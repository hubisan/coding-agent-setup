---
name: adopt-agent-setup
description: Adopt or refresh the coding-agent-setup template in this repo.
disable-model-invocation: true
---

# Adopt agent setup

Bring this repo onto the shared agent setup from `hubisan/coding-agent-setup`
(the **template**), new repo or grown one. The template owns the generic files; this
repo owns its project rules. Your job is the **merge**: every project rule survives,
every generic file comes from the template.

Work on branch `chore/agent-setup`. Each step ends on its criterion; ask the user
whenever a step needs a decision the repo cannot answer.

## 1. Fetch the template

Clone `https://github.com/hubisan/coding-agent-setup` into a temporary directory
outside this repo. Read its `sync-manifest.txt`: it names every generic file and its
mode (`sync` overwrites, `seed` only when missing, `import` = `CLAUDE.md`, a plain
`@AGENTS.md`).

Done when the clone exists and you know the mode of each listed path.

## 2. Inventory

Run `<template>/scripts/sync-coding-agent-setup.sh --dry-run .` and read this repo's
existing agent instructions: `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`, plus
CI, `Makefile`/scripts and test commands. List for the user:

- **conflicts**: `CLAUDE.md` with own content;
- **updates** to `sync` files that this repo changed locally (diff them: a local change
  is either a project rule to move into `AGENTS.md`, or a template improvement to
  propose upstream);
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
doc it points to.

Done when the dry run reports zero conflicts and no project rule lives only in a
`sync` file.

## 4. Sync and merge

Run `<template>/scripts/sync-coding-agent-setup.sh .`. Then merge the template into
each kept seed file:

- `AGENTS.md`: take the template's section structure (Start here, Progressive
  disclosure, Repository guardrails, Agent skills) and slot every existing project rule
  into it; fill or delete each `PROJECT` placeholder. Keep it pointer-only; load the
  `writing-for-agents` skill for this edit.
- `Makefile`: a `ci` target that runs the repo's full check (format, lint, tests).
- `.github/workflows/ci.yml`: runs `make ci` with the repo's toolchain setup.

Done when `grep -rn PROJECT AGENTS.md Makefile .github` finds nothing and
`make ci` runs the real check.

## 5. Configure skills and labels

Run `/setup-matt-pocock-skills`. Its `## Agent skills` block goes into `AGENTS.md`,
also when the skill proposes `CLAUDE.md`. Keep `docs/agents/triage-labels.md` from
the template. Then run `scripts/labels-setup.sh` (needs `gh`). Show the user
which existing labels are not in the table; add `--prune` to delete them only after
the user agrees, after moving issues that carry them (e.g. `wontfix` → closed as not
planned).

Done when `docs/agents/issue-tracker.md` and `domain.md` exist and the labels exist
or the user has the command.

## 6. Deliver

Run `make ci`, commit (Conventional Commits, e.g. `chore: adopt agent setup`), push,
open a PR. The PR body lists the merged project rules, the decided contradictions,
the template improvements to propose upstream, and every check left unrun.

Done when the PR is open.
