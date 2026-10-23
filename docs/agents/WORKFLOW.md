# Agent workflow

## Work artifact order

Prefer the most downstream existing artifact:

`ticket > spec > conversation`

Do not repeat upstream discovery when the downstream artifact already resolves the
decision. Planning may happen outside the coding agent; once the resulting spec,
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

- The planner is the main session; the user selects its model/effort (`/model`,
  `/effort`). Subagent model and effort are fixed in `.claude/agents/*.md`.
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

Repository skills live in `.claude/skills/` (Claude Code reads only this) and as an
identical copy in `.agents/skills/` (Codex). Copies, not symlinks. Skills marked
`disable-model-invocation` run only when the user invokes them. Invoke a matching skill
through the Skill tool (other harnesses: open its `SKILL.md` and follow it).

Mandatory use:

| Situation | Skill |
| --- | --- |
| Review of a ticket that changes code | `code-review` (planner, before commit) |
| Creating or editing the glossary or an ADR, or a term/decision is being settled | `domain-modeling` |
| Turning a settled conversation into a spec / tickets | `to-spec`, then `to-tickets` |
| Implementing a ticket with behaviour change | `tdd` (implementer) |
| Hard bug, flaky or unexplained failure | `diagnosing-bugs` |
| Editing `AGENTS.md`, `CLAUDE.md`, agent docs or skills | `writing-for-agents` |

Skip on purpose (token cost without benefit):

- `code-review` for docs-only, config-only or purely mechanical changes (renames,
  generated files, formatting); the planner's own diff review is enough there.
- Any skill for Git/GitHub housekeeping (commit, PR, merge, labels).

Update skills only on a `chore/skills-update` branch and review the diff before
committing.

- Repository overrides for `implement`: "full test suite" means the final CI below;
  commit per the Commits section. Project-specific overrides: `AGENTS.md`.
- `code-review`: fixed point is the commit before the ticket's first commit (or
  `HEAD` plus working tree via `git diff HEAD` before committing). The spec source is
  the active GitHub ticket issue and its spec issue. Standards sources are `AGENTS.md`
  and the project docs it points to, including its guardrails.
- Re-running `setup-matt-pocock-skills`: keep the `## Agent skills` block in
  `AGENTS.md`; `CLAUDE.md` stays a plain `@AGENTS.md` import.

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
scope change, a needed change to the functional specification, the DB, or the architecture, or the same
structural failure repeating. Final-CI format/lint fixes are not a correction cycle; a
failing test that needs a code change is.

## Testing

- The implementer runs the narrowest relevant tests while working.
  The focused test command is in `AGENTS.md`, "Repository guardrails".
- Full CI once at the end of a completed package: `make ci` (same command as
  `.github/workflows/ci.yml`).
- Keep command output compact; inspect detailed logs only when a step fails.
- Never claim checks passed when their environment (OS, browser, DB) was unavailable;
  report them as unverified.

## Context budget

Load context progressively. Prefer targeted searches and ranges over broad reads.
Do not scan `.agents/skills/` or `.claude/skills/`. Subagent briefs name the exact
files and sections to load so the implementer does not rediscover them.

Do not rerun commands merely because output was long. Narrow the next inspection to
the relevant file, symbol, error, or line range.

Repository skill installations use copied files rather than symlinks so Windows, WSL,
and archived handoffs see the same bytes reliably.

## Commits

Agents may commit on the current feature branch, one commit per completed ticket
after review and focused tests (or after final CI for the last ticket of a package).
Tick the ticket's acceptance criteria in the issue and close it through the PR
(`Closes #<n>` in the PR body).

- Commit messages follow Conventional Commits 1.0.0, in English:
  `<type>(<scope>): <imperative summary>`. Types: `feat`, `fix`, `refactor`, `test`,
  `docs`, `chore`, `build`, `ci`, `perf`. Scope is the feature slug or area (e.g.
  `login`, `db`, `ui`); `!` after the scope marks a breaking change.
- Ticket commits add a footer `Refs: #<ticket>` so `code-review` finds the spec
  source.
- Branches are always named `<type>/<feature-slug>` using the same types
  (e.g. `feat/user-export`, `fix/date-rounding`, `chore/agent-workflow`). This also applies to cloud sessions: a generated
  harness branch name (e.g. `claude/<random-words>`) is not used for pushes or PRs;
  create a descriptively named branch from the current base instead. One branch per
  coherent change; start the next change on a new branch from the updated base.
- Never commit secrets, `.env`, or generated output (see `AGENTS.md`).
  Never rewrite shared history; push, PR and merge follow `AGENTS.md`.

## Completion

Before declaring a package complete:

1. review the diff against the active ticket/spec;
2. run the final CI possible in the current environment;
3. update `CHANGELOG.md` for user-visible or contract-relevant changes, before the
   final commit;
4. state what was implemented, what was tested, what remains untested, and the next
   ticket without implementing it unless requested.
