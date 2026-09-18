---
name: new-course
description: Set up one or more new course folders in the current project for studying in Claude Code - detects unscaffolded folders, lets the user pick which are current courses, derives a topic outline from each course's materials, and writes CLAUDE.md, study_guide.md and the TUTOR.md copy. Use when course folders have been added, or the user asks to add/set up/prepare a course.
---

# Set up new course folders

Prepares one or more course folders inside the directory Claude Code is currently
running in, so each can be opened directly in Claude Code and tutored. Run this from
that root directory — Claude Code opened inside a single course folder cannot see
siblings or the parent's TUTOR.md.

Read `SETUP-NOTES.md` in the root first; it documents how the pieces fit together.

## What a prepared course folder looks like

```
<COURSE>\
  CLAUDE.md       <- course-specific; imports @TUTOR.md and @study_guide.md
  TUTOR.md        <- plain copy of the root TUTOR.md (kept current by sync-tutor.ps1)
  study_guide.md  <- Source Documents manifest + checkbox topic outline
  <the course materials, untouched>
```

`generated\` is not created here — the tutor makes it on first use.

## Step 1 — Identify the folders

If the user named folders, use those. Otherwise list candidates:

```bash
for d in */; do d="${d%/}"; [ "$d" = ".claude" ] && continue
  [ -f "$d/study_guide.md" ] || echo "UNSCAFFOLDED: $d"; done
```

**Then stop and confirm with the user before touching anything.** Some folders here
may be past or inactive courses that must stay untouched. An unscaffolded folder is
not automatically a course the user is taking. Show the list and ask which of them
(any subset, including all) are current courses to set up.

Then run Steps 2–4 for each confirmed folder, one folder at a time, in the order given.
Finish a folder completely before starting the next. Steps 5–7 run once at the end.

## Step 2 — Survey the materials

```bash
find "<COURSE>" -type f | sort
```

Note what is lecture material vs. reference vs. data. Textbooks, cheat sheets and datasets
are references, not study topics.

Extract structure from the documents — this is the part that makes the outline useful, so
do not skip it and do not invent topics from the folder name:

```bash
# Text and headings from a PDF (pdftotext is at /mingw64/bin/pdftotext)
pdftotext -l 30 "<COURSE>/<file>.pdf" - | tr -s '\n' | head -120

# Page count for a large PDF, to decide whether to sample or read a range
python -c "import pypdf;print(len(pypdf.PdfReader('<COURSE>/<file>.pdf').pages))"

# A textbook's contents pages, once you know roughly where they are
pdftotext -f 6 -l 12 "<COURSE>/<book>.pdf" - | tr -s '\n' | head -160
```

What to look for:
- **Agenda / "Lesson Plan" / "What you will learn" slides** — these give the deck's own
  topic list, in the instructor's wording. Best possible source.
- **Skip course logistics.** Orientation content — syllabus walkthroughs, Canvas/Colab
  workflow, "how this course works," meet-the-team, assignment submission mechanics — is
  not study material and never becomes an outline topic, even when a lecture's own agenda
  lists it as a numbered item. It has no exam content to recall.
- **A roadmap slide** listing future units — capture these as unchecked placeholders so
  the outline reflects the whole course, not just what has arrived.
- **A textbook's table of contents** when the decks track its chapter numbering.
- Folder names that are already topic-shaped (`Material\Trees - Topic 9`, `Week 7`).

Read enough to name topics accurately. Do **not** extract full content — that is the
tutor's job during a session.

## Step 3 — Write `study_guide.md`

```markdown
# <CODE> — <Course Name>

## Source Documents
_Last synced: <today>_

- `<lecture file>.pdf` — <what it covers>

Reference (not study topics on their own):
- `<textbook/cheat sheet/dataset>`

## Progress
0 / <N> topics complete

## Outline

### <Module/Unit 1 name>
- [ ] 1.1 <topic>
- [ ] 1.2 <topic>

### Upcoming — announced but not yet in the folder
_No materials yet. Break these out when the slides arrive._
- [ ] <unit from the roadmap slide>
```

Rules:
- **`study_guide.md` is an index, never a content store.** Manifest, progress count, and
  outline — nothing else. No explanations, definitions, summaries, tables of facts, or
  transcribed slides. One line per topic. This file is re-read in full at the start of
  every session for the rest of the course, so anything added to it is paid for on every
  future session. All three existing guides are ~2.1 KB; that is the target.
- Every topic is `- [ ]`. Progress always starts at `0 / N`; N = the count of `- [ ]` lines.
- Number topics to match the instructor's own scheme (`1.4`, `SWE-3`, `Topic 6`).
- Note empty folders explicitly (e.g. "`New folder\` is currently empty") so the tutor's
  staleness check has an explanation rather than a surprise.
- Never list `CLAUDE.md`, `TUTOR.md`, `study_guide.md` or `generated\` in Source Documents.

If the folder has an existing study guide or notes file, **adapt it rather than discard
it**: restructure its headings into the checkbox outline, and move its body verbatim to
`<COURSE>\generated\<name>-notes.md` — never into `study_guide.md`, which would violate
the index rule above. Label the archived file as derived and non-authoritative. Verify
with `diff` before deleting the original.

## Step 4 — Write `CLAUDE.md`

```markdown
# <CODE> — <Course Name>

Tutoring instructions: @TUTOR.md
Study plan: @study_guide.md

Course materials live in this folder. See `study_guide.md` → **Source Documents** for
what the study plan currently covers; anything in the folder that isn't listed there
means the plan is out of date.

Course specifics worth knowing:
- <instructor, textbook, tools>
- <how the course is assessed, if the slides say>
- <anything that should colour every explanation — a running case study, a required
  notation, a dataset used throughout>
```

Keep it short and course-specific. Tutoring behaviour belongs in `TUTOR.md`, never here.

## Step 5 — Copy `TUTOR.md` and register the courses

Once every confirmed folder has its `study_guide.md` and `CLAUDE.md`, run
`sync-tutor.ps1` from the project root **once** — it auto-detects every course folder
(any folder containing a `study_guide.md`) and copies the canonical `TUTOR.md` into
each one, the new ones included. Do not hardlink: Cowork's file bridge (the
alternative runtime) refuses to read hardlinked files.

```powershell
& "./sync-tutor.ps1"
```

## Step 6 — Verify

The sync output should show `synced (<stamp>)` for each new course. For each one also
check:

- `grep -c '^- \[ \]' <COURSE>/study_guide.md` matches the `## Progress` denominator.
- `<COURSE>` contains exactly `CLAUDE.md`, `TUTOR.md`, `study_guide.md` and the materials.

## Step 7 — Report

For each course, tell the user the topic count, what the outline was derived from, and
anything you were unsure about (a deck with no agenda slide, an empty subfolder, a
document you could not classify).

Then tell them how to study: open a **new** Claude Code session inside one course folder
(`cd <COURSE>` then `claude`), not the repo root, so the other courses stay out of
context. The session should open with
`<CODE> — 0/N complete · tutor <stamp>. Next up: <topic>. Ready?`

Nothing needs pasting or prompting; `CLAUDE.md` is auto-loaded and its `@` imports
resolve. (Cowork works too, with a project scoped to the course folder — see README.)

## Cautions

- **Never modify course materials.** Only add the three files.
- **Never touch a folder the user hasn't confirmed** is a current course.
- Don't edit the canonical `TUTOR.md` from here. If it needs changing, that is a separate
  request — edit the root copy, then run `sync-tutor.ps1`.
- If a `study_guide.md` already exists, the folder is already set up. Stop and ask whether
  the user wants it refreshed instead of overwriting it.
