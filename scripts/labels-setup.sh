#!/usr/bin/env bash
# Create or update the triage labels from docs/agents/triage-labels.md on GitHub
# (name, colour, meaning). Existing labels are recoloured, never deleted.
# Usage: scripts/labels-setup.sh [owner/repo]   (default: repo of the current clone)
set -euo pipefail

cd "$(dirname "$0")/.."
repo_args=()
[[ $# -ge 1 ]] && repo_args=(--repo "$1")

# Table rows: | upstream | `label` | `colour` name | meaning |
grep -E '^\| [^-]' docs/agents/triage-labels.md | tail -n +2 |
  while IFS='|' read -r _ _ label colour meaning _; do
    label=$(sed -E 's/[` ]//g' <<<"$label")
    colour=$(grep -oE '[0-9a-f]{6}' <<<"$colour")
    desc=$(sed -E 's/^ +| +$//g; s/;.*//' <<<"$meaning" | cut -c1-100)
    gh label create "$label" --color "$colour" --description "$desc" --force "${repo_args[@]}"
  done
