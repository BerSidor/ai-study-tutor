# AI Study Tutor — project root

This folder is a tutoring workflow, not a single course. Each course lives in
its own subfolder (gitignored — you add your own after cloning) and is opened
directly for studying; this root only holds the shared machinery.

Start here:
- **`README.md`** — its **Quick start** is the setup sequence. Read this first if you
  just cloned the repo.
- **`SETUP-NOTES.md`** — how the pieces are wired internally.
- **`TUTOR.md`** — canonical tutor instructions, copied into each course folder.
- **`EXAMPLE101/`** — a worked example of a fully scaffolded course folder.

If asked to add or set up a course, use the `/new-course` skill
(`.claude/skills/new-course/`) rather than improvising — it surveys the
materials, confirms with the user before touching anything, and writes the
`CLAUDE.md` / `study_guide.md` / `TUTOR.md` copy a course folder needs.

Do not tutor from this root file. Tutoring behavior belongs in `TUTOR.md`, and
course-specific facts belong in that course's own `CLAUDE.md`. Study sessions are run
by opening Claude Code inside the course folder, where that `CLAUDE.md` auto-loads.

Never use the `/teach` skill in this project. It is an unrelated global skill that
does not know this layout; tutoring runs through each course's `TUTOR.md` only.
