#!/usr/bin/env bash
# Regression tests for scripts/sync-coding-agent-setup.sh. Runs against a throwaway
# copy of the current working tree; prints one line per check, exits 1 on a failure.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
check() { local name=$1; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else fail "$name"; fi; }
check_not() { local name=$1; shift; if "$@" >/dev/null 2>&1; then fail "$name"; else ok "$name"; fi; }

git_q() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@" -q; }

# Template: copy of the working tree as a fresh git repo.
tpl="$tmp/template"
mkdir "$tpl"
(cd "$repo" && git ls-files -co --exclude-standard -z | xargs -0 cp --parents -t "$tpl")
git_q -C "$tpl" init
git -C "$tpl" add -A && git_q -C "$tpl" commit -m base
sync() { "$tpl/scripts/sync-coding-agent-setup.sh" "$@"; }
new_target() { local d="$tmp/$1"; mkdir -p "$d"; git_q -C "$d" init; echo "$d"; }

# Static checks on the template itself.
check "skill copies identical" diff -r "$repo/.claude/skills" "$repo/.agents/skills"
check_not "no symlinks in repo" test -n "$(cd "$repo" && find . -path ./.git -prune -o -type l -print)"
check "scripts executable" test -x "$repo/scripts/sync-coding-agent-setup.sh" -a -x "$repo/scripts/labels-setup.sh"
check "dry run on fresh target" sync --dry-run "$(new_target dry)"
check_not "dry run writes nothing" test -e "$tmp/dry/AGENTS.md"

# Fresh install, then idempotent rerun.
t=$(new_target fresh)
check "fresh install" sync "$t"
check "version recorded" test "$(cat "$t/.agent-setup-version")" = "$(git -C "$tpl" rev-parse HEAD)"
check "skills copied" diff -r "$tpl/.claude/skills" "$t/.claude/skills"
git -C "$t" add -A && git_q -C "$t" commit -m adopt
check "rerun succeeds" sync "$t"
check "rerun changes nothing" test -z "$(git -C "$t" status --porcelain)"

# Seed keeps the project version.
echo "# project rules" > "$t/AGENTS.md"
check "seed kept" sync "$t"
check "seed content preserved" grep -q "project rules" "$t/AGENTS.md"

# Import conflict: CLAUDE.md with own content blocks everything.
t2=$(new_target import)
echo "# own rules" > "$t2/CLAUDE.md"
check_not "import conflict fails" sync "$t2"
check_not "import conflict writes nothing" test -e "$t2/AGENTS.md"

# Local change to a sync file is a conflict; template update passes.
echo "local tweak" >> "$t/docs/agents/WORKFLOW.md"
check_not "local change fails" sync "$t"
check "local change kept" grep -q "local tweak" "$t/docs/agents/WORKFLOW.md"
git -C "$t" checkout -q -- docs/agents/WORKFLOW.md
echo "template change" >> "$tpl/docs/agents/WORKFLOW.md"
git_q -C "$tpl" commit -am update
check "template update syncs" sync "$t"
check "template update applied" grep -q "template change" "$t/docs/agents/WORKFLOW.md"
check "version advanced" test "$(cat "$t/.agent-setup-version")" = "$(git -C "$tpl" rev-parse HEAD)"

# Symlink on a target path is a conflict; the outside file stays untouched.
t3=$(new_target symlink)
mkdir "$tmp/outside"
ln -s "$tmp/outside" "$t3/docs"
check_not "symlinked dir fails" sync "$t3"
check "outside untouched" test -z "$(ls -A "$tmp/outside")"
check_not "no version after conflict" test -e "$t3/.agent-setup-version"

# In-repo symlinks (skills CLI layout) are allowed and written through.
t4=$(new_target inrepo)
mkdir -p "$t4/.agents/skills/tdd" "$t4/.claude/skills"
ln -s ../../.agents/skills/tdd "$t4/.claude/skills/tdd"
check "in-repo symlink allowed" sync "$t4"
check "symlink kept" test -L "$t4/.claude/skills/tdd"

# Dirty template is refused.
echo dirty >> "$tpl/README.md"
check_not "dirty template refused" sync --dry-run "$(new_target dirty)"

echo
if ((fails)); then echo "$fails check(s) failed"; exit 1; fi
echo "all checks passed"
