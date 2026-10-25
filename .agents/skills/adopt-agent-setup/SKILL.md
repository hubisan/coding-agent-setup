---
name: adopt-agent-setup
description: Adopt or refresh the coding-agent-setup template in this repo.
disable-model-invocation: true
---

# Adopt agent setup

Bring this repo onto the shared agent setup from `hubisan/coding-agent-setup`
(the **template**): an empty repo, a grown one, or an update of an adopted one. The template owns the generic files; this
repo owns its project rules. Your job is the **merge**: every project rule survives,
every generic file comes from the template.

Work on branch `chore/agent-setup`. Each step ends on its criterion; ask the user
whenever a step needs a decision the repo cannot answer.

## 1. Fetch the template

Clone `https://github.com/hubisan/coding-agent-setup` into a temporary directory
outside this repo. Read its `sync-manifest.txt`: it names every generic file and its
mode (`sync` overwrites, `seed` only when missing, `import` = `CLAUDE.md`, a plain
`@AGENTS.md`). If this repo has `.agent-setup-version`, it is an **update**: show the
user `git -C <template> log --oneline <recorded-sha>..HEAD` as the changes to adopt.

Done when the clone exists, you know the mode of each listed path, and on an update
the user has seen the template changes.

## 2. Inventory

Run `<template>/scripts/sync-coding-agent-setup.sh --dry-run .` and read this repo's
existing agent instructions: `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`, plus
CI, `Makefile`/scripts and test commands. List for the user:

- **conflicts**: `CLAUDE.md` with own content, `sync` files changed locally since the
  recorded version, symlinks on a target path;
- **updates** marked "no recorded version" (first adoption): diff each one, since the
  script cannot tell a local change from an older template;
- each local change is either a project rule to move into `AGENTS.md`, or a template
  improvement to propose upstream;
- **kept** seed files that need the template parts merged in (step 4);
- **extra** files and own skills whose name matches a template skill;
- project rules that contradict `docs/agents/WORKFLOW.md` (branch names, commits,
  merge rule, roles).

Done when every listed path is classified and the user has decided each
contradiction.

## 3. Move instructions into AGENTS.md

`AGENTS.md` is the single instruction file; `CLAUDE.md` is only `@AGENTS.md`.
Move the content of an existing `CLAUDE.md` into `AGENTS.md` (merge duplicates, keep
the wording of project rules), then make `CLAUDE.md` the single import line. Move
local changes to `sync` files that are project rules into `AGENTS.md` or a project
doc it points to, then restore those files (`git checkout` of the last synced state or
a copy from the template). Replace a symlink on a target path with a real directory
only after the user agrees.

Done when the dry run reports zero conflicts and no project rule lives only in a
`sync` file.

## 4. Sync and merge

Run `<template>/scripts/sync-coding-agent-setup.sh .`. Seeds it just added carry
`PROJECT` placeholders; fill them from the repo and the user. Merge the template into
each kept seed file:

- `AGENTS.md`: take the template's section structure (Start here, Read when,
  Repository guardrails, Agent skills) and slot every existing project rule
  into it; fill or delete each `PROJECT` placeholder. Keep it pointer-only; load the
  `writing-for-agents` skill for this edit.
- `Makefile`: a `ci` target that runs the repo's full check (format, lint, tests).
- `.github/workflows/ci.yml`: runs `make ci` with the repo's toolchain setup.

Done when `grep -rn PROJECT AGENTS.md Makefile .github` finds nothing and
`make ci` runs the real check.

## 5. Configure skills and labels

Run `/setup-matt-pocock-skills`; it creates or confirms `docs/agents/issue-tracker.md`
and `domain.md` for this repo. Its `## Agent skills` block goes into `AGENTS.md`,
also when the skill proposes `CLAUDE.md`. If it rewrites
`docs/agents/triage-labels.md`, restore the template version. Then run `scripts/labels-setup.sh` (needs `gh`). Show the user
which existing labels are not in the table; add `--prune` to delete them only after
the user agrees, after moving issues that carry them (e.g. `wontfix` → closed as not
planned).

Done when `docs/agents/issue-tracker.md` and `domain.md` exist and the tracker
holds exactly the labels the user agreed to.

## 6. Deliver

Run `make ci`, commit together with `.agent-setup-version` (Conventional Commits,
e.g. `chore: adopt agent setup`), push, open a PR. The PR body lists the merged project rules, the decided contradictions,
the template improvements to propose upstream, and every check left unrun.

Done when the PR is open.
