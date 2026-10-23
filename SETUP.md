# Setup-Prompt für ein neues Repo

Nach "Use this template" (oder nach dem ersten Sync) diesen Prompt in der ersten
Session verwenden:

---

Richte das Agenten-Setup in diesem Repo ein. Arbeite auf dem Branch `chore/agent-setup`.

1. Führe `/setup-matt-pocock-skills` aus. Der Skill will in `CLAUDE.md` schreiben,
   sobald es existiert: Schreibe den Block stattdessen in `AGENTS.md`. Es erzeugt `docs/agents/issue-tracker.md`
   und `docs/agents/domain.md` und füllt den Block `## Agent skills` in `AGENTS.md`.
   `docs/agents/triage-labels.md` bleibt wie es ist (inkl. Label `geparkt`).
   `CLAUDE.md` bleibt ein reiner `@AGENTS.md`-Import.
2. Fülle alle `PROJECT`-Platzhalter in `AGENTS.md` (Zweck des Repos, Spec-Ablage, Projekt-Doku, Guardrails, fokussierter
   Testbefehl, Overrides für Skills). Frage mich, was du nicht aus dem Repo ableiten kannst. Halte
   `AGENTS.md` kurz und nur mit Verweisen; nutze dafür den Skill `writing-for-agents`.
3. Ersetze das Ziel `ci` im `Makefile` durch den echten Check (Format, Lint, Tests)
   und ergänze die Toolchain-Schritte in `.github/workflows/ci.yml`.
4. Lege die Triage-Labels aus `docs/agents/triage-labels.md` im Issue-Tracker an,
   falls sie fehlen.
5. Führe `make ci` aus, committe (Conventional Commits) und öffne einen PR.

---

Generische Dateien (siehe `sync-manifest.txt`, Modus `sync`) nicht im Projekt ändern,
sondern in `coding-agent-setup`.
