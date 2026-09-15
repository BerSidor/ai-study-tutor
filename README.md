# College Material — setup guide

This folder is a tutoring system. Each course is a folder you open as its own **Cowork
project**; the agent reads that folder's instructions on its own and runs a study session
against the course's real materials.

This README is the **setup checklist** — everything *you* have to do for it to work.
For how the pieces are wired internally, see `SETUP-NOTES.md`. For how sessions are
actually run, see `TUTOR.md`.

---

## What has to exist

At the root of `College Material\`:

| Item | Purpose |
|---|---|
| `TUTOR.md` | canonical tutor instructions — the single source of truth |
| `.claude\skills\new-course\` | the `/new-course` skill that scaffolds a course folder |
| `SETUP-NOTES.md` | internal notes on how the wiring works |
| `README.md` | this file |

Inside **each active course folder**:

| Item | Purpose |
|---|---|
| the course materials | slides, PDFs, notebooks — the authority for what's taught |
| `CLAUDE.md` | course-specific facts; imports `@TUTOR.md` and `@study_guide.md` |
| `TUTOR.md` | a plain copy of the canonical root `TUTOR.md`, refreshed by `sync-tutor.ps1` |
| `study_guide.md` | source-document manifest + progress count + checkbox outline |
| `generated\` | everything the agent produces (created on first use) |

Currently set up: **COP3540**, **CEN5035**, **CAP4770**.
Deliberately not set up: `CEN3062C`, `COP3410C`, `CAP Labs` — past courses, leave alone.

---

## One-time setup

### 1. Add a course

Drop the course's materials into a new folder under `College Material\`.

### 2. Scaffold it

Open **Claude Code** (not Cowork) in `College Material\` and run:

```
/new-course
```

The skill surveys the materials, derives a topic outline from the documents themselves,
and writes `CLAUDE.md`, `study_guide.md` and the `TUTOR.md` copy. It asks for
confirmation before touching any folder — several folders here are past courses and it
cannot tell those from a new one on its own.

**Why Claude Code and not Cowork:** a Cowork project is scoped to a single course folder,
so from inside one it can see neither its sibling courses nor the canonical `TUTOR.md`
it needs to copy from.

### 3. Create the Cowork project

In Cowork, create a project pointed at the **course folder itself** —
`C:\Users\berna\College Material\COP3540`, not the parent.

Leave the project's **Instructions** field empty. Cowork auto-loads `CLAUDE.md` from the
project folder and resolves its `@` imports, so the whole chain runs unassisted:

```
open project -> CLAUDE.md auto-read -> @TUTOR.md + @study_guide.md pulled in
             -> session-start protocol runs
```

Repeat steps 1–3 per course.

---

## Studying

Open the course's Cowork project and start the chat. That's the whole trigger — no slash
command, no pasted prompt.

Start a **new chat for each session**. Progress is durable in `study_guide.md`, so a
fresh chat loses nothing; long Cowork chats re-cache the context repeatedly and cost a
lot. That is the reason this system exists.

### Health check on the opener

A correct session opens with a line like:

```
COP3540 — 4/31 complete · tutor 2026-09-10. Next up: 1.4 Levels of abstraction...
```

| Symptom | Meaning | Fix |
|---|---|---|
| No progress line | startup protocol was skipped | say "run your startup steps" |
| `tutor` date older than your other courses | that folder's copy wasn't synced after the last edit; it's running a stale ruleset | run `sync-tutor.ps1` |

---

## Maintenance

### Adding new materials mid-semester

Drop the file into the course folder. The next session will notice it isn't in
`study_guide.md` → **Source Documents** and offer to extend the outline.

### Editing `TUTOR.md`

The root `TUTOR.md` is canonical; each course folder has a **plain copy**. Edit the root
one (any tool), then push it out:

```powershell
& "C:\Users\berna\College Material\sync-tutor.ps1"
```

(They used to be hardlinks. Cowork's file bridge stopped reading hardlinked files in
September 2026, so copies it is.)

Then **bump the `Version:` stamp** — the staleness detection in the session opener
depends entirely on that stamp changing when the content does. Use that day's date, or
append the next letter if it already reads today (`2026-09-10` -> `2026-09-10b`).

The full step-by-step is **Change pipeline — editing TUTOR.md** in `SETUP-NOTES.md`.

The sync script prints `synced (<stamp>)` per course after a hash check; `MISMATCH`
means rerun it.

---

## Known limitations

- **Hooks do not fire in Cowork.** SessionStart and other lifecycle hooks from
  `~/.claude/settings.json` or `.claude/settings.json` are not run — Cowork is built on
  Claude Code but skips them (feature requests anthropics/claude-code #47993, #63360).
  Open a course folder in Claude Code instead if you want one. A hook's ceiling is
  detection anyway: it can flag a stale study guide, not rewrite the outline.
- **CLAUDE.md auto-loading is observed, not documented.** Verified live in a CEN5035
  session on 2026-09-09 with an empty Instructions field. If it ever stops working, put a
  pointer — not a copy of the rules — into **Project → Instructions**:

  ```
  You are my tutor for CEN5035 — Principles of Software Engineering.
  Read TUTOR.md in the project folder and follow it for the whole session.
  Start by running its session-start protocol before anything else.
  ```
