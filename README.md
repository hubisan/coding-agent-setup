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
| `docs/agents/triage-labels.md`, `scripts/labels-setup.sh` | Triage-Labels (Kategorie und Status) mit Farben; Skript legt sie per `gh` an, `--prune` löscht übrige | sync |
| `docs/agents/issue-tracker.md`, `domain.md` | Konfiguration dieses Repos (von `/setup-matt-pocock-skills`) | – |
| `CLAUDE.md` | nur `@AGENTS.md` (Absicherung, siehe oben) | sync |
| `AGENTS.md`, `Makefile`, `.github/workflows/ci.yml` | Gerüst mit `PROJECT`-Platzhaltern | seed |
| `.gitattributes`, `.editorconfig` | LF/UTF-8 | seed |

`sync` = wird beim Sync überschrieben. `seed` = wird nur kopiert, wenn die Datei fehlt;
danach gehört sie dem Projekt. `import` (`CLAUDE.md`) = wird nur geschrieben, wenn sie
fehlt oder schon `@AGENTS.md` ist; hat sie eigenen Inhalt, bricht der Sync ab, ohne
etwas zu schreiben. Die Liste steht in `sync-manifest.txt`.

Nicht enthalten, weil projektspezifisch: `docs/agents/CURRENT.md`, `domain.md`,
`issue-tracker.md` (erzeugt `/setup-matt-pocock-skills`) und Projekt-Doku.

## Setup in ein Repo übernehmen

Das Skript kopiert nur. Das Zusammenführen mit bestehenden Regeln macht die KI mit dem
Skill `adopt-agent-setup` (`.claude/skills/adopt-agent-setup/SKILL.md`): Bestand
aufnehmen, `CLAUDE.md` nach `AGENTS.md` verschieben, syncen, Platzhalter und CI
füllen, `/setup-matt-pocock-skills`, Labels, PR auf `chore/agent-setup`.

Neue (auch leere) und bestehende Repos nutzen denselben Weg, per Prompt in einer
Session im Ziel-Repo:

> Übernimm das Agent-Setup aus https://github.com/hubisan/coding-agent-setup in dieses
> Repo. Klone das Template in ein temporäres Verzeichnis und folge dort
> `.claude/skills/adopt-agent-setup/SKILL.md`.

Später aktualisiert `/adopt-agent-setup` (der Skill ist dann im Repo) auf den neuen
Stand des Templates.

Ins Ziel kommen nur die Dateien aus `sync-manifest.txt`. README, `LICENSE`,
`docs/upstream/`, Sync-Skript, Manifest und die Konfiguration dieses Repos
(`issue-tracker.md`, `domain.md`) bleiben hier.

Jeder erfolgreiche Sync schreibt den Commit des Templates nach `.agent-setup-version`
im Ziel-Repo (mitcommitten). Daran erkennt der nächste Sync lokale Änderungen an
`sync`-Dateien: Er meldet sie als Konflikt und schreibt dann nichts. Beim Update zeigt
der Skill die Template-Änderungen seit diesem Stand.

Nur kopieren, ohne KI (Linux/WSL; löscht nichts, meldet `extra`):

```bash
scripts/sync-coding-agent-setup.sh --dry-run ../mein-repo
scripts/sync-coding-agent-setup.sh ../mein-repo
```

## Verbesserungen

1. Änderung zuerst hier machen (Branch `<type>/<slug>`, PR).
2. Danach in die Repos syncen.

Änderungen an `sync`-Dateien direkt im Ziel-Repo blockieren den nächsten Sync, bis sie
nach `AGENTS.md` oder ins Template verschoben sind.

## Optionales Muster: Fake-Daten-Modus

Für UI-Repos mit Datenbank hat sich bewährt: ein Modus mit In-Memory-Daten (ohne DB)
plus ein Screenshot-Skript, damit Agenten UI-Änderungen selbst ansehen können
(z. B. `scripts/run-fake.sh` startet die App mit Fake-Daten, `scripts/screenshot.mjs`
macht Screenshots in hellem und dunklem Modus).

## Lizenz

MIT, siehe `LICENSE`. Die Skills von `mattpocock/skills` stehen ebenfalls unter MIT
(`THIRD-PARTY-LICENSES.md`); die Datei wird mit den Skills synchronisiert.
