# Setup notes — how the tutoring system is wired

## Structure

```
<project root>\
  TUTOR.md          <- canonical tutor instructions
  README.md         <- setup checklist (what the user has to do)
  SETUP-NOTES.md    <- this file
  sync-tutor.ps1    <- copies TUTOR.md into every active course folder
  .claude\skills\new-course\   <- the /new-course scaffolding skill
  <COURSE>\
    CLAUDE.md       <- course-specific; imports @TUTOR.md and @study_guide.md
    TUTOR.md        <- plain copy of the canonical file (kept current by sync-tutor.ps1)
    study_guide.md  <- Source Documents manifest + Progress count + checkbox outline
    generated\      <- everything the agent creates (created on first use)
```

Past or inactive course folders are deliberately not set up.

## Claude Code is the primary runtime, not Cowork

This system was originally built and run through Cowork. It moved to Claude Code because
**Cowork re-injects its own system prompt on every new session**, which is a real,
recurring token cost stacked on top of everything this workflow already re-reads
(`TUTOR.md` + `study_guide.md` at the start of every session). Since minimizing
per-session overhead is this system's entire reason for existing — see **one topic per
session** in `TUTOR.md` — that made Cowork the more expensive way to run something
designed to be cheap.

Opening the course folder directly in Claude Code produces the same
`CLAUDE.md` auto-read -> `@TUTOR.md` + `@study_guide.md` -> session-start protocol chain,
without that extra cost, and picks up SessionStart hooks as a bonus (see below). Cowork
still works and is documented below as a fallback, but it is no longer the recommended
path.

## Cowork behavior — confirmed 2026-09-09

**Cowork auto-loads `CLAUDE.md` from the project folder and resolves its `@` imports.**
Verified in a live course session with nothing pasted into the project's Instructions
field: the agent opened with the correct progress line, ran the staleness check, and used
phrasing (`Next up`) that appears only in `TUTOR.md`.

So the chain works unassisted:

```
open project -> CLAUDE.md auto-read -> @TUTOR.md + @study_guide.md pulled in
             -> session-start protocol runs
```

**Nothing needs to be pasted into the Cowork Instructions field.** This is not in the
Cowork documentation, which describes the Instructions field but says nothing about
CLAUDE.md auto-loading — it was established by observation, so if behavior ever changes,
see the fallback below.

### Health check

A session should open with a line like:

```
EXAMPLE101 — 0/16 complete · tutor 2026-09-10. Next up: 0.1 Course structure...
```

- **No progress line** = the startup protocol was skipped. Say "run your startup steps."
- **An older `tutor` date than the other courses** = that folder's `TUTOR.md` copy was not
  synced after the last edit and it is running a stale ruleset. Run `sync-tutor.ps1`.

**When you edit `TUTOR.md`, bump its `Version:` line to that day's date.** The whole
detection scheme depends on the date changing when the content changes.

### Fallback, only if auto-loading stops working

Paste this into **Project → Instructions**, changing the course name and prefix:

```
You are my tutor for <COURSE CODE> — <Course Name>.
Read TUTOR.md in the project folder and follow it for the whole session.
Start by running its session-start protocol before anything else.
```

Keep it to a pointer like this. Don't restate the rules — `TUTOR.md` is the single source.

## Hooks do not work in Cowork

SessionStart (and other) hooks from `~/.claude/settings.json` or `.claude/settings.json`
**do not fire in Cowork sessions**. Cowork is built on Claude Code but does not run its
lifecycle hooks — open feature requests anthropics/claude-code #47993 and #63360.

A hook would fire if a course folder is opened in **Claude Code** instead. Worth adding
then: it runs before the model gets a turn, the only genuinely deterministic option here.
Its ceiling is detection — a hook runs a shell command and injects output, so it can flag
a stale study guide but cannot rewrite the outline.

## Editing TUTOR.md — important

The root `TUTOR.md` is canonical; each course folder holds a **plain copy**, pushed there
by `sync-tutor.ps1`. Edit only the root copy, with any tool, then run the sync.

**Why copies, not hardlinks (changed 2026-09-14):** the folders were hardlinked until
Cowork's file bridge started refusing to read hardlinked files ("cloud-placeholder file
the bridge won't read"), while plain files in the same folder read fine. Copies cost one
extra step per edit; hardlinks cost the tutor its rulebook.

**Bumping the stamp.** Every edit must change the `Version:` stamp — that is the entire
detection scheme. If the stamp already reads today's date, append the next letter
(`2026-09-10` -> `2026-09-10b`). A same-day edit that leaves the stamp alone is the one
case a bare date cannot catch: a copy that detached earlier today still reports the
current stamp and looks healthy. Bump the example openers inside `TUTOR.md` too, so the
stamp appears consistently.

If the sync is skipped, the root keeps the change and the three course copies stay at the
old version — which is what the `tutor <date>` stamp in the session opener is there to
expose. Repair by running the sync.

Sync and verify after any edit:

```powershell
& "./sync-tutor.ps1"
```

It prints one `synced (<stamp>)` line per course after a hash comparison. `MISMATCH`
means the copy failed — rerun it.

## Change pipeline — editing TUTOR.md

Follow this in order for any change to tutoring behavior. Steps 3 and 5 are the ones that
actually go wrong.

1. **Confirm the target.** Tutoring behavior lives in `TUTOR.md`. It does **not** live in
   the `/teach` skill at `~\.claude\skills\teach\` — that skill is unrelated to this
   project and editing it changes nothing here. Course-specific facts go in the course's
   own `CLAUDE.md`; topic lists go in `study_guide.md`.

2. **Check the cost rule before adding text.** `TUTOR.md` is read in full at the start of
   every session, in every course, forever. A paragraph added here is paid every session
   for the rest of the semester. Add rules; never add content.

3. **Edit the root `TUTOR.md` only.** Any tool is fine now that the course files are
   plain copies. Never edit a course copy directly — the next sync overwrites it.

4. **Bump the `Version:` stamp**, including the example openers inside the file. Use the
   next-letter suffix if the stamp already reads today (see above).

5. **Sync the copies.**

   ```powershell
   & "./sync-tutor.ps1"
   ```

   Expect `synced (<new stamp>)` for every course. Skipping this step is the failure
   mode: the root changes and every course silently keeps running the old ruleset.

6. **Verify the content landed.** Grep the new section back out of a *course* copy, not
   the root one — that proves both the edit and the sync in a single check.

7. **Record what was non-obvious** in project memory: dead ends, tool behavior, anything
   that cost time. Not the change itself — these notes already hold that.

## Adding a course later

Drop the materials into a new folder here, then run **`/new-course`** in Claude Code from
this directory. The skill (`.claude/skills/new-course/`) lists every unscaffolded folder,
asks which ones (any number) are current courses, then for each surveys the materials,
derives a topic outline from the documents themselves, and writes `CLAUDE.md`,
`study_guide.md` and the `TUTOR.md` copy. `sync-tutor.ps1` auto-detects the new courses
(any folder with a `study_guide.md`), so nothing needs to be registered manually.

It asks for confirmation before touching any folder — several folders here are past
courses that must stay untouched, and it cannot tell those from a new one on its own.

Studying is then one Claude Code session per course, opened inside that course folder so
siblings stay out of context — see **Quick start** in `README.md`.

Run it from Claude Code, not Cowork: a Cowork project is scoped to a single course folder,
so it can see neither its siblings nor the canonical `TUTOR.md` it needs to copy.
