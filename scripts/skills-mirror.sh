#!/usr/bin/env bash
# Build .claude/skills (read by Claude Code) from .agents/skills (the real skills,
# read by Codex). Mode from .agent-setup.conf: skills=link (default) makes
# .claude/skills/<name> a symlink to ../../.agents/skills/<name>; skills=copy makes a
# real copy, for repos that must work on Windows without WSL.
# .claude/skills is derived: edit skills in .agents/skills. Run after every skill update.
# Usage: scripts/skills-mirror.sh [repo-path]   (default: this repo)
set -euo pipefail

cd "${1:-$(dirname "$0")/..}"
mode=link
if [[ -f .agent-setup.conf ]]; then
  mode=$(sed -n 's/^skills=//p' .agent-setup.conf | tail -n1)
fi
case "$mode" in link | copy) ;; *)
  echo "error: .agent-setup.conf: skills must be link or copy, not '$mode'" >&2
  exit 1
esac

mkdir -p .claude/skills
for src in .agents/skills/*/; do
  name=$(basename "$src")
  dst=".claude/skills/$name"
  if [[ "$mode" == link ]]; then
    [[ -L "$dst" && "$(readlink "$dst")" == "../../.agents/skills/$name" ]] && continue
    rm -rf "$dst"
    ln -s "../../.agents/skills/$name" "$dst"
  else
    [[ ! -L "$dst" && -d "$dst" ]] && diff -rq "$src" "$dst" >/dev/null && continue
    rm -rf "$dst"
    cp -r "$src" "$dst"
  fi
  echo "  $mode  $dst"
done

# Entries without a source are reported, never deleted.
for dst in .claude/skills/*; do
  [[ -e "$dst" || -L "$dst" ]] || continue
  name=$(basename "$dst")
  if [[ ! -d ".agents/skills/$name" ]]; then
    echo "  extra $dst (no .agents/skills/$name: move it there or delete it)"
  fi
done
