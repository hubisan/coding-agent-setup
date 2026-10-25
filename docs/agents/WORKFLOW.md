# Agent workflow

## Work artifact order

The artifact order (`AGENTS.md`) means: when a downstream artifact settles a
decision, build on it and skip the upstream discovery. Planning may happen outside the coding agent; once the resulting spec,
ticket, ADR, or domain doc is checked into the repository, treat it as authoritative
for its scope.

Normal flow: `/to-spec` -> `/to-tickets` (usually done by the user, often in a separate
chat) -> planner plans one ticket -> implementer subagent -> focused tests -> planner
review -> at most one correction -> final CI -> commit.

## Roles and model routing

| Role | Claude Code | Codex |
| --- | --- | --- |
| Planner and reviewer | main session; model and effort chosen in the session | main session; model and effort chosen in the session |
| Implementer (default) | subagent `implementer`: Sonnet, effort medium | subagent: Sol, effort medium |
| Escalated implementer | subagent `implementer-escalated`: Sonnet, effort high | subagent: Sol, effort high |

Model names carry no version: the current model of that family is meant.

- The user sets the planner's model and effort (`/model`, `/effort`); subagent model
  and effort are fixed in `.claude/agents/*.md`.
- The planner reads the ticket, writes a short plan (owned files, seam, focused test
  command, relevant project-doc sections), and delegates to `implementer`.
- Parallelise for speed: start as many implementers at once as there are independent
  slices (disjoint files, no shared migration or generated file), each in its own worktree
  (`isolation: "worktree"`) so checkouts and uncommitted files never mix. Slices that
  touch the same files run one after another.
- The implementer fixes ordinary test failures itself and returns a compact report.
- The planner reviews. For high-risk tickets (data writes, transactions, concurrency,
  security) the planner may raise its own effort for the review.
- `implementer-escalated` and any `xhigh`/`max` effort require explicit user approval.
- Git/GitHub housekeeping (branch, commit, push, PR create/merge, issues, labels)
  stays in the planner session. It costs few tokens; delegating it to a subagent
  costs more (briefing + context) than it saves.
- Other harnesses keep the same three roles with their own models.

## Skills

Repository skills live in `.agents/skills/` (read by Codex); edit and add them only
there. `.claude/skills/` (the only place Claude Code reads) is derived by
`scripts/skills-mirror.sh`: symlinks into `.agents/skills/`, or real copies when
`.agent-setup.conf` says `skills=copy` (repos that must run on Windows without WSL).
Invoke a matching skill through the Skill tool (other harnesses: open its `SKILL.md` and follow it).

Mandatory use:

| Situation | Skill |
| --- | --- |
| Review of a ticket that changes code | `code-review` (planner, before commit) |
| Creating or editing the glossary or an ADR, or a term/decision is being settled | `domain-modeling` |
| Implementing a ticket with behaviour change | `tdd` (implementer) |
| Hard bug, flaky or unexplained failure | `diagnosing-bugs` |
| Editing `AGENTS.md`, `CLAUDE.md`, agent docs or skills | `writing-for-agents` |

Skills marked `disable-model-invocation` (e.g. `to-spec`, `to-tickets`, `triage`,
`implement`) start only when the user types them; when one fits, suggest it.

Skip on purpose (token cost without benefit):

- `code-review` for docs-only, config-only or purely mechanical changes (renames,
  generated files, formatting); the planner's own diff review is enough there.
- Any skill for Git/GitHub housekeeping (commit, PR, merge, labels).

Update skills on a `chore/skills-update` branch, then run `scripts/skills-mirror.sh`.

- Repository overrides for `implement`: "full test suite" means the final CI below;
  commit per the Commits section. Project-specific overrides: `AGENTS.md`.
- `code-review`: fixed point is the commit before the ticket's first commit (or
  `HEAD` plus working tree via `git diff HEAD` before committing). The spec source is
  the active GitHub ticket issue and its spec issue. Standards sources are `AGENTS.md`
  and the project docs it points to, including its guardrails.
- `setup-matt-pocock-skills`: its `## Agent skills` block goes into `AGENTS.md`, also
  when the skill proposes `CLAUDE.md`; `CLAUDE.md` stays a plain `@AGENTS.md` import.

## Documentation layout

Where skills and agents put documents; the skill defaults apply where this table is
silent.

| Document | Location | Written by |
| --- | --- | --- |
| Specs and tickets | GitHub issues (`.scratch/<feature>/` only with a local tracker) | `to-spec`, `to-tickets` |
| Glossary, ADRs | `GLOSSARY.md`, `docs/adr/` | `domain-modeling` |
| Coding standards (judgement calls; mechanical rules become checks) | `CODING_STANDARDS.md` | `retro`, by hand |
| Research notes | `docs/research/<slug>.md` | `research` |
| Rejected enhancements | `.out-of-scope/` | `triage` |
| Handoffs | OS temp directory, outside the repo | `handoff` |

## Correction budget

Initial implementation, including its own red/green fixes, does not count.

Maximum correction cycles after the first review: **1**.

A finding is **substantial** when an acceptance criterion is missing or wrong, a
repository guardrail is violated, behaviour is incorrect, or a test is missing
for changed behaviour. Naming, style, and code-smell judgement calls are not
substantial: report them, fix them only inside an already-planned correction.

1. First review finds a substantial issue: the planner adjusts the plan and delegates
   one focused correction.
2. Second review still finds a substantial issue: stop and ask the user. No further
   correction and no escalation without approval.

Also stop and ask when a failure exposes a wrong architectural assumption, a material
scope change, a needed change to the functional specification, the DB, or the
architecture, or the same structural failure repeating. Final-CI format/lint fixes are not a correction cycle; a
failing test that needs a code change is.

## Testing

- The implementer runs the narrowest relevant tests (focused test command:
  `AGENTS.md`) while working.
- Full CI once at the end of a completed package: `make ci`, the same command as
  `.github/workflows/ci.yml`.

## Context budget

Subagent briefs name the exact files and sections to load, so the implementer starts
where the planner stopped.

Keep command output compact. When output is long, narrow the next inspection to the
relevant file, symbol, error, or line range; open detailed logs only when a step fails.

## Commits

One commit per completed ticket
after review and focused tests (or after final CI for the last ticket of a package).
Tick the ticket's acceptance criteria in the issue and close it through the PR
(`Closes #<n>` in the PR body).

- Commit messages follow Conventional Commits 1.0.0, in English:
  `<type>(<scope>): <imperative summary>`. Types: `feat`, `fix`, `refactor`, `test`,
  `docs`, `chore`, `build`, `ci`, `perf`. Scope is the feature slug or area (e.g.
  `login`, `db`, `ui`); `!` after the scope marks a breaking change.
- Ticket commits add a footer `Refs: #<ticket>` so `code-review` finds the spec
  source.
- Branches are named `<type>/<feature-slug>` with the same types (e.g.
  `feat/user-export`, `fix/date-rounding`). Cloud sessions too: create such a branch
  from the current base in place of the generated harness branch (e.g.
  `claude/<random-words>`). One branch per coherent change; start the next change from
  the updated base.
- Shared history stays as pushed: add commits, never rewrite. Merge rule: `AGENTS.md`.

## Completion

Before declaring a package complete:

1. review the diff against the active ticket/spec;
2. run the final CI possible in the current environment;
3. if the repo keeps a `CHANGELOG.md`, update it for user-visible or contract-relevant
   changes before the final commit;
4. state what was implemented, what was tested, what remains untested, and the next
   ticket without implementing it unless requested.
