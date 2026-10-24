# Triage labels

Colours: yellow = needs a maintainer, green = ready to work, blue = accepted but not
scheduled, grey = resting, red = problem, violet = information.

| Label in mattpocock/skills | Label in our tracker | Colour | Meaning |
| --- | --- | --- | --- |
| `bug` | `bug` | `d73a4a` red | Category: something is broken |
| `enhancement` | `enhancement` | `8250df` violet | Category: new feature or improvement |
| – (repo-specific) | `documentation` | `c5a3f5` light violet | Category: documentation only |
| `needs-triage` | `needs-triage` | `fbca04` yellow | Maintainer needs to evaluate this issue |
| `needs-info` | `needs-info` | `f5e08a` light yellow | Waiting for more information |
| `ready-for-agent` | `ready-for-agent` | `1aa58c` blue-green | Fully specified and agent-ready |
| `ready-for-human` | `ready-for-human` | `2da44e` green | Requires human implementation |
| – (repo-specific) | `backlog` | `1d76db` blue | Accepted and ready, but not scheduled yet; replaces the state label. Do not start unless the user asks. |
| – (repo-specific) | `someday` | `bfbfbf` grey | Maybe later; deliberately postponed by the user, not committed to; replaces the state label. Do not start unless the user asks. |
| – (repo-specific) | `duplicate` | `b60205` dark red | Duplicate of another issue or PR; link it, then close as duplicate |

`wontfix` has no label: close the issue with reason "not planned" and the comment the
`triage` skill asks for.

Every triaged issue carries one category label and one state label.
When a skill names a canonical triage role, use the corresponding tracker label.
Create or recolour the labels with `scripts/labels-setup.sh` (reads this table);
`--prune` also deletes every other label of the repo.
