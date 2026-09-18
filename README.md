# Course Tutor — setup guide

This folder is a tutoring system. Each course is a folder you open directly — in
**Claude Code** (recommended) or a Cowork project — and the agent reads that folder's
instructions on its own and runs a study session against the course's real materials.

This README is the **setup checklist** — everything *you* have to do for it to work.
For how the pieces are wired internally, see `SETUP-NOTES.md`. For how sessions are
actually run, see `TUTOR.md`.

---

## Quick start

The whole setup is two Claude Code sessions: one at the repo root to scaffold, then one
per course to study.

**1. Clone the repo.** Open a terminal (or Claude Code with no folder) and:

```
git clone <repo-url>
cd <repo>
```

**2. Add your courses.** Inside the repo, make one top-level folder per course and drop
that course's materials into it — slides, PDFs, notebooks, whatever the instructor gave
you:

```
<repo>\
  COP3540\   <- your files
  CEN5035\   <- your files
  EXAMPLE101\   <- shipped with the repo; a finished example you can compare against
```

Course folders are gitignored, so nothing personal is ever pushed.

**3. Scaffold them.** Start Claude Code **from the repo root** and run the skill:

```
claude
/new-course
```

It lists every unscaffolded folder and asks which ones are courses you're taking — pick
all of them. For each one it reads the materials, derives a topic outline, and writes the
three files a course needs (`CLAUDE.md`, `study_guide.md`, `TUTOR.md`). Exit when it
reports done.

**4. Study — one session per course.** Open a **new** Claude Code session inside the
course folder, not the repo root:

```
cd COP3540
claude
```

Claude Code only reads the folder it's opened in, so sibling courses stay out of context
and out of the bill. The course's `CLAUDE.md` auto-loads and pulls in `TUTOR.md` and
`study_guide.md`; nothing to paste, no slash command. Just start chatting.

**5. Check the opener.** A working session begins with the tutor's standard progress
line:

```
COP3540 — 4/31 complete · tutor 2026-09-15. Next up: **2.4 Keys**. Ready?
```

If that line doesn't appear, say "run your startup steps". If the `tutor` date is older
than in your other courses, run `sync-tutor.ps1` from the root (see **Maintenance**).

Start a **new chat for each session** — progress lives in `study_guide.md`, so a fresh
chat loses nothing and stays cheap.

Everything below is reference detail for the steps above.

---

## What has to exist

At the root of the project folder:

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

Past or inactive course folders should be left alone — the `/new-course` skill
always confirms with you before touching an unscaffolded folder, so it won't
mistake one for a course you're currently taking.

---

## About `/new-course`

The skill lives in `.claude\skills\new-course\`. It must run from the **repo root** in
Claude Code — from inside a course folder it can see neither its siblings nor the
canonical `TUTOR.md` it needs to copy. It asks for confirmation before touching any
folder, because a folder of old materials from a past semester looks the same as a new
course, and it never modifies your materials — it only adds the three files.

Adding a course mid-semester is the same: make the folder, run `/new-course` from the
root, pick it.

---

## Studying

### Why Claude Code instead of Cowork

This system was originally built and run through Cowork, with a project pointed at the
course folder. It still works there — but Cowork re-injects its own system prompt on
**every new session**, on top of everything this workflow already re-reads
(`TUTOR.md` + `study_guide.md`). Since "cheap, short, resumable sessions" is the entire
point of this setup (see `SETUP-NOTES.md`), that per-session overhead works against the
goal. Plain Claude Code, opened in the course folder, does not carry that cost and produces
the same session-start protocol and progress tracking — so it's now the primary way to run
this.

Cowork still works as an alternative if you prefer its UI:

1. Create a Cowork project pointed at the **course folder itself**, not the parent.
2. Leave the project's **Instructions** field empty — Cowork auto-loads `CLAUDE.md` the
   same way Claude Code does.
3. See **Known limitations** below for a Cowork-specific gap (hooks don't fire there).

### Health check on the opener

A correct session opens with a line like:

```
EXAMPLE101 — 4/31 complete · tutor 2026-09-15. Next up: **2.4 Keys**. Ready?
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
& "./sync-tutor.ps1"
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

These apply to the **Cowork alternative** only; Claude Code doesn't have either issue.

- **Cowork re-injects its own system prompt every new session**, on top of what this
  workflow already re-reads. That per-session cost is the main reason Claude Code is now
  the recommended way to run this — see **Why Claude Code instead of Cowork** above.
- **Hooks do not fire in Cowork.** SessionStart and other lifecycle hooks from
  `~/.claude/settings.json` or `.claude/settings.json` are not run — Cowork is built on
  Claude Code but skips them (feature requests anthropics/claude-code #47993, #63360). A
  hook's ceiling is detection anyway: it can flag a stale study guide, not rewrite the
  outline.
- **CLAUDE.md auto-loading in Cowork is observed, not documented.** Verified live in a
  course session with an empty Instructions field. If it ever stops
  working, put a pointer — not a copy of the rules — into **Project → Instructions**:

  ```
  You are my tutor for <COURSE CODE> — <Course Name>.
  Read TUTOR.md in the project folder and follow it for the whole session.
  Start by running its session-start protocol before anything else.
  ```
