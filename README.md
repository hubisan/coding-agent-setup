# coding-agent-setup

Vorlage für das Agenten-Setup unserer Repos: Skills, Rollen, Workflow und Sync-Skript
an einem Ort. Funktioniert mit **Claude Code** und **Codex**.

- `AGENTS.md` ist die einzige Anweisungsdatei. Codex liest sie direkt, Claude Code ab
  v2.1.277 auch.
- `CLAUDE.md` enthält nur `@AGENTS.md`. Es sichert ältere Claude-Versionen ab und
  Sessions mit `CLAUDE.local.md` (das schaltet das direkte Lesen von `AGENTS.md` ab).
  Doppelt geladen wird nichts.
- Claude Code liest nichts unter `.agents/`. Skills und Subagents brauchen deshalb
  `.claude/`; `.agents/skills/` ist die Kopie für Codex.

Dieses Repo ist die einzige Quelle für das generische Setup. Andere Repos kopieren
es und erfinden es nicht neu.

## Inhalt

| Pfad | Zweck | Sync |
| --- | --- | --- |
| `.claude/skills/`, `.agents/skills/`, `skills-lock.json` | Matt-Pocock-Skills (identische Kopien, keine Symlinks) | sync |
| `.claude/agents/implementer*.md` | Implementer-Subagents (Standard und eskaliert) | sync |
| `docs/agents/WORKFLOW.md` | Rollen, Parallelisierung, Korrekturbudget, Commits, Skills | sync |
| `docs/agents/triage-labels.md`, `scripts/labels-setup.sh` | Triage-Labels inkl. `backlog` und `someday`, mit Farben; Skript legt sie per `gh` an | sync |
| `docs/agents/issue-tracker.md`, `domain.md` | Konfiguration dieses Repos (von `/setup-matt-pocock-skills`) | – |
| `CLAUDE.md` | nur `@AGENTS.md` (Absicherung, siehe oben) | sync |
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

## Optionales Muster: Fake-Daten-Modus

Für UI-Repos mit Datenbank hat sich bewährt: ein Modus mit In-Memory-Daten (ohne DB)
plus ein Screenshot-Skript, damit Agenten UI-Änderungen selbst ansehen können
(Beispiel: `controlling-db-web`, `scripts/run-fake.sh`, `scripts/screenshot.mjs`).
