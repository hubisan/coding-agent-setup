# coding-agent-setup

Vorlage für das Agenten-Setup unserer Repos: Skills, Rollen, Workflow und Sync-Skript
an einem Ort. Funktioniert mit **Claude Code** (liest `CLAUDE.md` → `@AGENTS.md`)
und **Codex** (liest `AGENTS.md`).

Dieses Repo ist die einzige Quelle für das generische Setup. Andere Repos kopieren
es und erfinden es nicht neu.

## Inhalt

| Pfad | Zweck | Sync |
| --- | --- | --- |
| `.claude/skills/`, `.agents/skills/`, `skills-lock.json` | Matt-Pocock-Skills (identische Kopien, alle model-invocable) | sync |
| `scripts/skills-update.sh`, `make skills-update` | Skills aktualisieren, Kopie und Flag-Entfernung sicherstellen | sync |
| `.claude/agents/implementer*.md` | Implementer-Subagents (Standard und eskaliert) | sync |
| `docs/agents/WORKFLOW.md` | Rollen, Parallelisierung, Korrekturbudget, Commits, Skills | sync |
| `docs/agents/triage-labels.md` | Triage-Labels inkl. `geparkt` | sync |
| `CLAUDE.md` | nur `@AGENTS.md` | sync |
| `AGENTS.md`, `Makefile`, `.github/workflows/ci.yml` | Gerüst mit `PROJECT`-Platzhaltern | seed |
| `.gitattributes`, `.editorconfig` | LF/UTF-8 | seed |

`sync` = wird beim Sync überschrieben. `seed` = wird nur kopiert, wenn die Datei fehlt;
danach gehört sie dem Projekt. Die Liste steht in `sync-manifest.txt`.

Nicht enthalten, weil projektspezifisch: `docs/agents/CURRENT.md`, `domain.md`,
`issue-tracker.md` (erzeugt `/setup-matt-pocock-skills`) und Projekt-Doku.

## Neues Repo

1. Auf GitHub **Use this template** → neues Repo erstellen.
2. In der ersten Agenten-Session den Prompt aus `SETUP.md` verwenden.

## Bestehendes Repo

```bash
scripts/sync-coding-agent-setup.sh --dry-run ../mein-repo   # zeigt, was sich ändert
scripts/sync-coding-agent-setup.sh ../mein-repo
cd ../mein-repo && git switch -c chore/agent-setup && git diff
```

Das Skript läuft unter Linux/WSL. Es löscht nichts: Dateien, die nur im Ziel liegen
(z. B. entfernte Skills), meldet es als `extra`. Fehlen `AGENTS.md` oder `Makefile`,
danach die Schritte aus `SETUP.md` ausführen.

## Verbesserungen

1. Änderung zuerst hier machen (Branch `<type>/<slug>`, PR).
2. Danach in die Repos syncen.

Änderungen an `sync`-Dateien direkt im Ziel-Repo gehen beim nächsten Sync verloren.

Skills aktualisieren: `make skills-update` (oder `make skills-update SKILLS="tdd"`),
Diff prüfen, auf `chore/skills-update` committen.

## Optionales Muster: Fake-Daten-Modus

Für UI-Repos mit Datenbank hat sich bewährt: ein Modus mit In-Memory-Daten (ohne DB)
plus ein Screenshot-Skript, damit Agenten UI-Änderungen selbst ansehen können
(Beispiel: `controlling-db-web`, `scripts/run-fake.sh`, `scripts/screenshot.mjs`).
