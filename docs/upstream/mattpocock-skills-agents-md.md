# Draft issue for mattpocock/skills

Title: setup-matt-pocock-skills: prefer AGENTS.md over CLAUDE.md

**Problem.** Step 4 of `setup-matt-pocock-skills` edits `CLAUDE.md` whenever it exists
and only falls back to `AGENTS.md`. A common setup keeps all instructions in
`AGENTS.md` (read by Codex and other agents) with a one-line `CLAUDE.md` containing
`@AGENTS.md`. The skill then writes the `## Agent skills` block into the import file,
so Codex and other agents never see it.

Claude Code now reads `AGENTS.md` natively (since v2.1.277, when no `CLAUDE.md`
exists), so `AGENTS.md` is the portable choice.

**Proposal.** Pick the file in this order:

1. `AGENTS.md` if it exists.
2. Else `CLAUDE.md` if it exists, unless it only imports another file
   (`@AGENTS.md`): then edit the imported file.
3. If neither exists, ask the user which one to create.
