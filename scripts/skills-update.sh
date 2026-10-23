#!/usr/bin/env bash
# Update repository skills from skills-lock.json sources and restore the repo
# conventions (docs/agents/WORKFLOW.md, "Skills"): .claude/skills is a real copy of
# .agents/skills, and no skill carries disable-model-invocation.
# Usage: scripts/skills-update.sh [skill ...]   (no args = all skills)
set -euo pipefail

SKILLS_CLI_VERSION="1.7.0"

cd "$(dirname "$0")/.."

# Skills that exist only in .claude/skills would be lost by the copy below.
only_claude=$(comm -23 <(ls .claude/skills | sort) <(ls .agents/skills | sort))
if [[ -n "$only_claude" ]]; then
  echo "error: skills only in .claude/skills (add them to .agents/skills first):" >&2
  echo "$only_claude" >&2
  exit 1
fi

npx -y "skills@${SKILLS_CLI_VERSION}" update --project --yes "$@"

# Strip the upstream invocation flag (no match is the normal case).
{ grep -rl --include=SKILL.md '^disable-model-invocation:' .agents/skills .claude/skills || true; } \
  | xargs -r sed -i '/^disable-model-invocation:/d'

# The CLI replaces .claude/skills entries with symlinks; restore a real copy.
rm -rf .claude/skills
cp -r .agents/skills .claude/skills

if find .claude/skills -type l | grep -q .; then
  echo "error: .claude/skills still contains symlinks" >&2
  exit 1
fi
if grep -rq --include=SKILL.md '^disable-model-invocation:' .agents/skills .claude/skills; then
  echo "error: disable-model-invocation still present" >&2
  exit 1
fi

echo "Skills updated. Review 'git diff --stat .agents/skills .claude/skills skills-lock.json'"
echo "and commit on chore/skills-update."
