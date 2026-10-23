#!/usr/bin/env bash
# Copy the generic agent setup into a target repo, as listed in sync-manifest.txt.
# "sync" entries are overwritten, "seed" entries are copied only when missing.
# Prints what changed; review with `git -C <target> diff` and commit there.
# Usage: scripts/sync-coding-agent-setup.sh [--dry-run] <target-repo-path>
set -euo pipefail

dry_run=0
if [[ "${1:-}" == "--dry-run" ]]; then dry_run=1; shift; fi
if [[ $# -ne 1 || ! -d "$1" ]]; then
  echo "usage: $0 [--dry-run] <target-repo-path>" >&2
  exit 2
fi

src="$(cd "$(dirname "$0")/.." && pwd)"
dst="$(cd "$1" && pwd)"
if [[ "$src" == "$dst" ]]; then
  echo "error: target is this repo" >&2
  exit 2
fi

added=0 updated=0 kept=0 same=0

copy_file() { # <mode> <relpath>
  local mode=$1 rel=$2 s="$src/$2" d="$dst/$2"
  if [[ ! -e "$d" ]]; then
    echo "  add     $rel"; added=$((added + 1))
  elif cmp -s "$s" "$d"; then
    same=$((same + 1)); return
  elif [[ "$mode" == seed ]]; then
    echo "  keep    $rel (project version)"; kept=$((kept + 1)); return
  else
    echo "  update  $rel"; updated=$((updated + 1))
  fi
  if ((!dry_run)); then
    mkdir -p "$(dirname "$d")"
    cp "$s" "$d"
    [[ -x "$s" ]] && chmod +x "$d"
  fi
  return 0
}

while read -r mode path _; do
  [[ -z "$mode" || "$mode" == \#* ]] && continue
  if [[ "$mode" != sync && "$mode" != seed ]]; then
    echo "error: unknown mode '$mode' in sync-manifest.txt" >&2
    exit 1
  fi
  if [[ -d "$src/$path" ]]; then
    while IFS= read -r f; do
      copy_file "$mode" "$path/$f"
    done < <(cd "$src/$path" && find . -type f | sed 's|^\./||' | sort)
    # Files only in the target are reported, never deleted.
    if [[ -d "$dst/$path" ]]; then
      while IFS= read -r f; do
        echo "  extra   $path/$f (not in coding-agent-setup; delete if obsolete)"
      done < <(comm -13 <(cd "$src/$path" && find . -type f | sort) \
                        <(cd "$dst/$path" && find . -type f | sort) | sed 's|^\./||')
    fi
  elif [[ -f "$src/$path" ]]; then
    copy_file "$mode" "$path"
  else
    echo "error: manifest entry missing in coding-agent-setup: $path" >&2
    exit 1
  fi
done < "$src/sync-manifest.txt"

((dry_run)) && echo "(dry run, nothing written)"
echo "added $added, updated $updated, kept $kept, unchanged $same"
echo "Review with: git -C '$dst' status && git -C '$dst' diff"
