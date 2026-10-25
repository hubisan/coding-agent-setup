#!/usr/bin/env bash
# Copy the generic agent setup into a target repo, as listed in sync-manifest.txt.
# Modes: "sync" overwrites unless the target changed it locally, "seed" copies only
# when missing, "import" copies when missing or already identical.
# Local changes are detected against the template commit recorded in the target's
# .agent-setup-version by the previous sync. Conflicts (local change, own import
# content, symlink leading outside the repo) are collected first: if any exists, nothing is written.
# Usage: scripts/sync-coding-agent-setup.sh [--dry-run] <target-repo-path>
set -euo pipefail

version_file=.agent-setup-version

dry_run=0
if [[ "${1:-}" == "--dry-run" ]]; then dry_run=1; shift; fi
if [[ $# -ne 1 || ! -d "$1" ]]; then
  echo "usage: $0 [--dry-run] <target-repo-path>" >&2
  exit 2
fi

src="$(cd "$(dirname "$0")/.." && pwd)"
dst="$(cd "$1" && pwd -P)"
if [[ "$src" == "$dst" ]]; then
  echo "error: target is this repo" >&2
  exit 2
fi

src_sha=$(git -C "$src" rev-parse HEAD)
if [[ -n "$(git -C "$src" status --porcelain)" ]]; then
  echo "error: template has uncommitted changes; commit them or use a clean clone" >&2
  exit 2
fi

base_sha=""
if [[ -f "$dst/$version_file" ]]; then
  base_sha=$(head -n1 "$dst/$version_file")
  if ! git -C "$src" cat-file -e "$base_sha^{commit}" 2>/dev/null; then
    echo "warning: recorded template commit $base_sha not in this clone; local changes undetectable" >&2
    base_sha=""
  fi
fi

added=0 updated=0 kept=0 same=0 conflicts=0
to_copy=()

conflict() { echo "  conflict  $1 ($2)"; conflicts=$((conflicts + 1)); }

# A symlink on the target path may point anywhere; writes must stay inside the repo.
# In-repo symlinks (e.g. .claude/skills/x -> ../../.agents/skills/x) are fine.
leaves_repo() {
  local real
  real=$(realpath -m "$dst/$1")
  [[ "$real" != "$dst/"* ]]
}

plan_file() { # <mode> <relpath>
  local mode=$1 rel=$2 s="$src/$2" d="$dst/$2"
  if leaves_repo "$rel"; then
    conflict "$rel" "symlink on the path leads outside the repo"; return
  fi
  if [[ ! -e "$d" ]]; then
    echo "  add       $rel"; added=$((added + 1))
  elif cmp -s "$s" "$d"; then
    same=$((same + 1)); return
  elif [[ "$mode" == seed ]]; then
    echo "  keep      $rel (project version)"; kept=$((kept + 1)); return
  elif [[ "$mode" == import ]]; then
    conflict "$rel" "own content; move it to AGENTS.md"; return
  elif [[ -z "$base_sha" ]]; then
    echo "  update    $rel (no recorded version: check the diff for local changes)"
    updated=$((updated + 1))
  elif git -C "$src" show "$base_sha:$rel" 2>/dev/null | cmp -s - "$d"; then
    echo "  update    $rel"; updated=$((updated + 1))
  else
    conflict "$rel" "changed locally since $base_sha; move project rules to AGENTS.md, then restore the template version"
    return
  fi
  to_copy+=("$rel")
}

while read -r mode path _; do
  [[ -z "$mode" || "$mode" == \#* ]] && continue
  case "$mode" in sync | seed | import) ;; *)
    echo "error: unknown mode '$mode' in sync-manifest.txt" >&2
    exit 1
  esac
  if [[ -d "$src/$path" ]]; then
    while IFS= read -r f; do
      plan_file "$mode" "$path/$f"
    done < <(cd "$src/$path" && find . -type f | sed 's|^\./||' | sort)
    # Files only in the target are reported, never deleted.
    if [[ -d "$dst/$path" && ! -L "$dst/$path" ]]; then
      while IFS= read -r f; do
        echo "  extra     $path/$f (not in coding-agent-setup; delete if obsolete)"
      done < <(comm -13 <(cd "$src/$path" && find . -type f | sort) \
                        <(cd "$dst/$path" && find . -type f | sort) | sed 's|^\./||')
    fi
  elif [[ -f "$src/$path" ]]; then
    plan_file "$mode" "$path"
  else
    echo "error: manifest entry missing in coding-agent-setup: $path" >&2
    exit 1
  fi
done < "$src/sync-manifest.txt"

if leaves_repo "$version_file"; then conflict "$version_file" "symlink leads outside the repo"; fi

echo "template ${base_sha:-none} -> $src_sha"
echo "added $added, updated $updated, kept $kept, unchanged $same, conflicts $conflicts"
if ((dry_run)); then
  echo "(dry run, nothing written)"
  exit 0
fi
if ((conflicts)); then
  echo "error: resolve the conflicts above, then run again; nothing written" >&2
  exit 1
fi
for rel in "${to_copy[@]}"; do
  mkdir -p "$(dirname "$dst/$rel")"
  cp "$src/$rel" "$dst/$rel"
  [[ -x "$src/$rel" ]] && chmod +x "$dst/$rel"
done
echo "$src_sha" > "$dst/$version_file"
echo "Review with: git -C '$dst' status && git -C '$dst' diff"
