#!/usr/bin/env bash
# Create or update the triage labels from docs/agents/triage-labels.md on GitHub
# (name, colour, meaning). Existing labels are recoloured, never deleted.
# Uses the REST API via `gh api`, so it also works where GraphQL is blocked.
# Usage: scripts/labels-setup.sh [owner/repo]   (default: repo of the current clone)
set -euo pipefail

cd "$(dirname "$0")/.."
repo=${1:-$(git remote get-url origin | sed -E 's#^.*github\.com[:/]##; s#\.git$##')}

# Table rows: | upstream | `label` | `colour` name | meaning |
grep -E '^\| [^-]' docs/agents/triage-labels.md | tail -n +2 |
  while IFS='|' read -r _ _ label colour meaning _; do
    label=$(sed -E 's/[` ]//g' <<<"$label")
    colour=$(grep -oE '[0-9a-f]{6}' <<<"$colour")
    desc=$(sed -E 's/^ +| +$//g; s/;.*//' <<<"$meaning" | cut -c1-100)
    if gh api "repos/$repo/labels/$label" --silent 2>/dev/null; then
      gh api -X PATCH "repos/$repo/labels/$label" -f color="$colour" -f description="$desc" --silent
      echo "updated $label"
    else
      gh api -X POST "repos/$repo/labels" -f name="$label" -f color="$colour" -f description="$desc" --silent
      echo "created $label"
    fi
  done
