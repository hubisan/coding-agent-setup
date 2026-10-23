# Triage labels

| Label in mattpocock/skills | Label in our tracker | Colour | Meaning |
| --- | --- | --- | --- |
| `needs-triage` | `needs-triage` | `fbca04` yellow | Maintainer needs to evaluate this issue |
| `needs-info` | `needs-info` | `d876e3` purple | Waiting for more information |
| `ready-for-agent` | `ready-for-agent` | `0e8a16` green | Fully specified and agent-ready |
| `ready-for-human` | `ready-for-human` | `1d76db` blue | Requires human implementation |
| `wontfix` | `wontfix` | `cccccc` grey | Will not be actioned |
| – (repo-specific) | `backlog` | `bfd4f2` light blue | Accepted and ready, but not scheduled yet; replaces the state label. Do not start unless the user asks. |
| – (repo-specific) | `someday` | `ededed` light grey | Maybe later; deliberately postponed by the user, not committed to; replaces the state label. Do not start unless the user asks. |

When a skill names a canonical triage role, use the corresponding tracker label.
Create or recolour the labels with `scripts/labels-setup.sh` (reads this table).
