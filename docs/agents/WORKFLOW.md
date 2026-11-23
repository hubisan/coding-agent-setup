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

**Codex Luna max fallback:** The preferred effort for `planner-light`, `implementer`
and `reviewer-light` is `max`. If the current Codex client rejects `max`
for a subagent, retry that same role using `gpt-6-luna` with
`model_reasoning_effort = "xhigh"`. This specific fallback is preapproved;
do not block the task waiting for another approval. Because subagent TOML
sets a fixed effort, first adjust the affected agent configuration for the
current run or use a supported explicit per-spawn override; a prose instruction
alone cannot change the effective effort. Keep persistent configuration changes
in a reviewed change, rather than silently committing them. Record the
requested effort, effective fallback and available runtime evidence. If `xhigh`
also fails, stop and ask instead of silently changing model families.


The main session coordinates work, Git and PRs. Select its model for cost. Delegate
planning, implementation and behavior-changing code review to role-specific agents.

**Routing trigger:** select the lowest-risk role that fits the ticket. Security,
data writes, migrations, concurrency and architecture changes use the complex role.
Route by risk before size; a one-line security change is still high-risk.

| Task | Role | Codex | Claude Code |
| --- | --- | --- | --- |
| Simple planning | `planner-light` | Luna max | Sonnet medium |
| Complex planning | `planner` | Sol medium | Opus medium |
| Small implementation | `implementer-light` | Luna high | Sonnet low |
| Normal implementation | `implementer` | Luna max | Sonnet medium |
| Complex implementation | `implementer-complex` | Sol medium | Opus medium |
| Focused test triage | `tester` | Luna high | Sonnet low |
| Normal code review | `reviewer-light` | Luna max | Sonnet medium |
| Complex code review | `reviewer` | Sol medium | Opus medium |
| Approved escalation | `implementer-escalated` | Sol high | Sonnet high |

**Source of truth:** Codex model IDs and effort live in `.codex/agents/*.toml`;
Claude model aliases and effort live in `.claude/agents/*.md`. This table is a
routing overview, not a second configuration. The session model is user-selected.
For Claude, prefer Sonnet low for coordination; for Codex, Luna high. Haiku is
excluded from default Claude routing.

### Delegate

1. **Plan:** Read the active ticket and the most downstream approved artifact.
   Skip re-planning when an adequate plan already exists. Delegate a missing plan
   to `planner-light` or `planner`. Done when the brief names owned files,
   dependencies, acceptance criteria and a focused test command.
2. **Implement:** Delegate the plan to the matching implementer with only the
   relevant paths and sections. Parallelize disjoint slices in separate worktrees;
   serialize changes to shared files or migrations. Done when the agent reports
   changed files and focused tests, or names a blocking assumption.
3. **Test:** The implementer runs focused tests and fixes ordinary failures.
   Delegate `tester` only for useful independent execution or triage. Done when
   test results and any unrun checks are recorded. Run full `make ci` once at
   package completion.
4. **Review:** Give behavior-changing diffs to an independent reviewer, never
   their implementer. Use `code-review` and check the ticket's criteria and
   guardrails. For docs-only, config-only or mechanical changes, coordinator
   diff inspection is enough. Done when the reviewer returns actionable findings
   with file/line references or explicitly reports none.
5. **Correct:** Send substantial findings to an implementer for one focused
   correction, following the correction budget below. Escalate to
   `implementer-escalated` only with user approval. Keep Git housekeeping in the
   main session.

### Verify model routing

**Configuration is not runtime evidence.** Before first delegation in a session,
check whether configured model IDs/aliases are supported. When reliable current
release information is available, warn once about superseded versions. Name the
affected agent and suggested replacement; request approval before changing config.

After each phase, record `phase / role / configured model / effort / evidence`.
Use one of these evidence states:

- `configured`: read the agent config; no spawn evidence
- `spawn-confirmed`: the selected agent started; runtime model not confirmed
- `runtime-verified`: independent client/task metadata shows effective model
  **and** effort, with its evidence location

For example: `review / reviewer / gpt-6.2-sol / medium / spawn-confirmed`.

Codex: inspect `/subagents` if supported. Claude Code: inspect `/tasks` while
the task is active if supported. Check overrides that can supersede configured
Claude agents, including per-invocation options and relevant environment variables.
Self-reports, config inspection and token usage are not runtime proof. Report
unknown effective models, mismatches and unavailable verification explicitly;
never infer that a cheaper model actually ran.

**Completion:** the final report includes the roles actually used, configured
model/effort, verification status, substantive review findings, focused-test results
and CI status. The coordinator does not claim verified model routing without
independent evidence.

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
