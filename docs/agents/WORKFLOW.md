# Agent workflow

## Work artifact order

The artifact order (`AGENTS.md`) means: when a downstream artifact settles a
decision, build on it and skip the upstream discovery. Planning may happen outside the coding agent; once the resulting spec,
ticket, ADR, or domain doc is checked into the repository, treat it as authoritative
for its scope.

Normal flow: `/to-spec` -> `/to-tickets` (usually done by the user, often in a separate
chat) -> planning subagent -> implementation subagent -> focused tests -> independent
review subagent -> at most one correction -> final CI -> main-session commit.

## Roles and model routing

The main session is an inexpensive **coordinator**, not the default planner or code
reviewer. In Codex it can use Luna high (user selects its session model). Delegate
planning and review to fixed-role subagents instead of inheriting the session model.

| Phase | Normal Codex role | Fixed model / effort | Escalation |
| --- | --- | --- | --- |
| Simple planning | `planner-light` | Luna max | `planner` (Sol medium) |
| Complex or risky planning | `planner` | Sol medium | User-approved higher-effort session |
| Small, mechanical implementation | `implementer-light` | Luna high | `implementer` (Luna max) |
| Normal implementation | `implementer` | Luna max | `implementer-complex` (Sol medium) |
| Complex or high-risk implementation | `implementer-complex` | Sol medium | `implementer-escalated` (Sol high; approval) |
| Targeted tests and failure triage | `tester` | Luna high | `implementer` (Luna max) |
| Normal code review | `reviewer-light` | Luna max | `reviewer` (Sol medium) |
| Complex, security-sensitive or data-risk review | `reviewer` | Sol medium | User-approved higher-effort session |

Claude Code keeps its configured subagents; do not assume Codex model IDs apply to
Claude. Codex exact model IDs are in `.codex/agents/*.toml`. Versionless family names
in this table are explanatory only. When a model is unsupported by the installed client,
stop, tell the user and request a supported replacement rather than silently
falling back to the coordinator model.

- The coordinator reads the ticket, chooses a planning role by complexity/risk, and
  gives it only the relevant scope and repository context. Planning must finish before
  implementation; treat an existing approved plan/spec as authoritative and do not
  re-plan merely because a phase exists.
- Delegate simple changes to `implementer-light`, ordinary features to
  `implementer`, and difficult or higher-risk code to `implementer-complex`.
  Escalating to `implementer-escalated` or any unlisted high-cost role needs user approval.
- The implementer runs focused tests itself. Use a separate `tester` only when
  independent test execution or failure triage actually saves work. Do not spawn a
  tester just to duplicate passing tests. Full CI runs once at package completion.
- An independent `reviewer-light` or `reviewer` reviews behavior-changing code;
  the implementer must not review its own work. For docs-only, config-only and
  mechanical diffs, the coordinator may inspect the diff without a review subagent.
- Route focused fixes back to `implementer-light` or `implementer`. Keep the
  correction budget below. Never repeat review cycles without a concrete finding.
- Parallelise only independent, disjoint implementation slices in separate worktrees;
  shared files or migrations run sequentially.
- Git/GitHub housekeeping (branch, commit, push, PR, merge and labels) stays in the
  main session. Do not spawn agents for it.

### Model verification and reporting

Before the first Codex delegation in each session, check configured model IDs against
models the current client exposes and check whether a newer supported release exists
when reliable release information is accessible. Warn once on unavailable, unsupported
or superseded IDs; name the agent, configured ID and proposed replacement. Do not
silently change configuration. If not verifiable, say so.

**Configuration is not proof of runtime use.** Some Codex client versions have
incorrectly inherited the parent model/effort when spawning custom subagents. For
each phase, provide a concise model-routing line:

`plan: planner / gpt-6.2-sol / medium / configured (runtime unverified)`

Use the actual agent, model and effort from its TOML; name the phase and state
`configured`, `spawn-confirmed`, or `runtime-verified`. A successful spawn
confirms the agent identity, not necessarily the runtime model. Mark
`runtime-verified` **only** with independent client/session metadata or logs that
show the effective model **and** effort for that subagent. Quote the evidence
location or command when available. Agent self-reports and TOML inspection alone
are insufficient. If a spawn fails or the effective model is unknown, report that
clearly; do not claim savings or a different model was used.

Before the final answer, show a compact summary of planned versus verified routing
for phases actually run, and flag mismatches. In the Codex CLI, inspect the active
subagent threads with `/subagents` when supported; model/effort visibility depends
on the client. Do not invent a verification command or infer runtime identity from
token consumption.

## Skills

Repository skills live in `.agents/skills/` (read by Codex); edit and add them only
there. `.claude/skills/` (the only place Claude Code reads) is derived by
`scripts/skills-mirror.sh`: symlinks into `.agents/skills/`, or real copies when
`.agent-setup.conf` says `skills=copy` (repos that must run on Windows without WSL).
Invoke a matching skill through the Skill tool (other harnesses: open its `SKILL.md` and follow it).

Mandatory use:

| Situation | Skill |
| --- | --- |
| Review of a ticket that changes code | `code-review` (review subagent, before commit) |
| Creating or editing the glossary or an ADR, or a term/decision is being settled | `domain-modeling` |
| Implementing a ticket with behaviour change | `tdd` (implementer) |
| Hard bug, flaky or unexplained failure | `diagnosing-bugs` |
| Editing `AGENTS.md`, `CLAUDE.md`, agent docs or skills | `writing-for-agents` |

Skills marked `disable-model-invocation` (e.g. `to-spec`, `to-tickets`, `triage`,
`implement`) start only when the user types them; when one fits, suggest it.

Skip on purpose (token cost without benefit):

- `code-review` for docs-only, config-only or purely mechanical changes (renames,
  generated files, formatting); the coordinator's diff inspection is enough there.
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

## Writing for people

Docs that people read (README, `docs/`, PR bodies, issues) use **plain language**, in
the spirit of ASD-STE100: answer first; short sentences, active voice; one term for one
meaning; define each technical term at first use; no filler. Agent instructions follow
the `writing-for-agents` skill instead.

## Correction budget

Initial implementation, including its own red/green fixes, does not count.

Maximum correction cycles after the first review: **1**.

A finding is **substantial** when an acceptance criterion is missing or wrong, a
repository guardrail is violated, behaviour is incorrect, or a test is missing
for changed behaviour. Naming, style, and code-smell judgement calls are not
substantial: report them, fix them only inside an already-planned correction.

1. First review finds a substantial issue: the coordinator adjusts the plan and delegates
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

1. review the diff against the active ticket/spec using the selected independent reviewer for code changes;
2. run the final CI possible in the current environment;
3. update every doc the change makes stale (README, `docs/`, `AGENTS.md` pointers,
   `CHANGELOG.md` if the repo keeps one) in the same PR; if none, say so;
4. state what was implemented, what was tested, what remains untested, and the next
   ticket without implementing it unless requested.
