<!-- Symlinked to ~/.claude/CLAUDE.md by config_claude.sh, so these follow you
 to every machine.  Keep it machine-independent; per-repo rules belong in that
 repo's own CLAUDE.md -->

# Working style

- NEVER start modifying files off an open-ended prompt. A message like
  "read the objectives file and let's continue closing things out" is a
  request to REVIEW and PROPOSE next steps - nothing more. Present the
  options, recommend one, and WAIT for an explicit go-ahead on a concrete
  action before touching any file, repo, or checkout. This has been
  violated before (2026-07-15: launched into merging lib branches when
  asked only to read objectives_cleanup.md). Do not do it again.
- Never recommend pushing a repo. Commit when asked, but leave pushing to me.
- Never fast-forward feature branch merges: always `git merge --no-ff` so the
  feature branch stays a cohesive unit in history.
- Whenever possible a submodule sits on its named branch, never a detached
  HEAD. `git submodule update` and `git pull --recurse-submodules` check it out
  AT THE RECORDED SHA, which detaches it: the local branch then stops tracking
  its remote, and anything committed from that state belongs to no branch.
  Update a submodule from inside it, with a plain `git fetch` and `git merge`
  on its own branch, so local and remote stay in sync. Where that is not an
  option, `git submodule update --merge` merges into the current branch instead
  of detaching.
- for commit headers - DEFINITELY don't violate the 80 characters rule; in fact
  try to keep the first line of a commit under 50 characters
- the commit message BODY wraps at 72, NOT the 80 used for .md prose: `git log`
  indents the message four spaces, so 72 is what still fits an 80-column
  terminal. Trailers (Co-Authored-By, session URLs) are never wrapped.


# Feature branch workflow: objectives_<feature_name>.md

Every new feature branch gets an `objectives_<feature_name>.md` at the repo
root, created when the branch starts. It begins with the OBJECTIVES of the
feature, then specific todo, and accumulates a working journal as the feature
progresses: findings, test results, design decisions and their reasoning - in
the style of a handoff doc that a fresh session could resume from.

- Update it as work happens; it is the running record, not an afterthought.
- It is a record, not an essay. Findings, results and decisions, a line or two
  each.
- It lives only on the feature branch: DELETE it when the feature is complete,
  alongside the merge. Its history remains in the branch's commits as the
  record of test results and design decisions.


# Documentation weight

Prose about code is a liability, not a free good: a reviewer has to read the
prose AND the code to find out whether the prose is still true. That is more
work than reading the code alone, which defeats the point. Every sentence has
to earn that cost. Default to none.

- The code documents WHAT it does. Do not restate command syntax, defaults,
  clamp ranges or message shapes in prose - they are one grep away, and they
  go stale silently.
- Comment the WHY only where it is not recoverable from the code: a hazard, a
  constraint imposed from outside the file (hardware, wire protocol, another
  repo), a measured number, or a decision someone would otherwise undo by
  accident.
- When you delete code, delete it. Do NOT leave a comment describing what used
  to be there, why it was wrong, or what replaced it - and never leave the code
  itself commented out or disabled behind an `&& 0`. Comment only what a reader
  of the code AS IT NOW STANDS needs in order to understand it. Err
  aggressively toward cutting: a comment that narrates history is worse than no
  comment, because the next reader cannot tell whether it still describes the
  file.
- Rejected alternatives and the reasoning behind a change go in the COMMIT
  MESSAGE. A commit describes one moment and can never go stale; a README
  describes the present and has to be maintained forever.
- README is what a person needs BEFORE reading the code - what the thing is,
  how the pieces connect, how to build and run it. It is not a manual.
- Do not gloss a well-named identifier. If a comment exists to explain a name,
  fix the name - a flag named *_BENCH needs no note saying it is bench only.
- Do not predict what the toolchain announces. An image that will not fit
  fails at link, an assert fires, a type error is a type error. Describing
  that failure adds nothing at the moment it happens, and rots in between.
- Measured numbers rot. A byte count, a timing, a sample size belongs in the
  commit message that measured it. Only invariants belong in code - a boundary
  address, a protocol constant.

Writing costs you nothing, so you will over-produce by default. "A human would
not have bothered to write this" is the signal to cut, not the ceiling to aim
at. Adding a comment needs a reason you can name, and two cheap tests find most
of the ones that have none:

- Apply the comment's logic to the whole repo. If every sibling would earn the
  same note - every flag "compiles it out", every bench knob "not for
  production" - then it carries no information here. Delete it.
- Name the specific mistake a reader makes without it. If you cannot, there is
  no reader to protect.


# Comments and docstrings

- Comments are short and concise.
- Add a Google style docstring to any function that is complex or whose purpose
  is not immediately obvious.
- Write code comments and docstrings in an impersonal voice. Never use first
  person (I/we/my/our) - state what the code does or why, not what the author
  wants. E.g. "The serial number is usually important" rather than "the thing
  I most want to see". Second person (you/your) is fine where it naturally
  addresses the reader or user, e.g. "the ports you care about".


# Python

- Unless otherwise specified, the target Python version is 3.12.
    - If the repository has a `uv.lock`, use uv rather than python directly -
      even for quick one-off scripts. Do not re-install uv.
- Strive for immutable data structures and patterns.
- Do not rely on falsy values (i.e. `if len(my_list)` or `if None`) - compare
  explicitly.
- Outside of tests, do not use `assert`.
- In Python, format strings with f-strings (`f"{x}"`) - never C/printf `%`-style
  (`"%s" % x`) or `str.format()`. Use nested specs like `f"{x:>{width}}"` for
  alignment.

Typing discipline and data container choice are repo conventions, not global
ones - follow what the repo already does.


# Tests

- The test framework is a repo convention. Use whatever the repo already uses.
- Don't test trivia - e.g. that a constant holds a certain value.
- A string captured from another tool's output WILL rot across releases. Two
  shipped bugs came from exactly that, both invisible until a bench ran a newer
  version of the tool. Where code has to match such a string, match every
  wording that means the same thing, in ONE place.


# Bash

- NEVER write inline multiline Python inside bash.
- For a multiline string or heredoc, use `EOF` as the delimiter.


# Code review

- Don't believe comments, intent included - question the premise. A makefile
  here justifies a leading `-` on the boot recipe with "no device attached must
  not fail to build", but `make boot` with no device SHOULD fail; only plain
  `make` has to keep working, and it does not require boot.
- Write review comments into a markdown file in the current directory, named
  `code-review-[branch name].md`. You have permission to read and write that
  file.
- When you complete a comment from that file, mark it done in the file.
- Never commit the review file.


# Writing and formatting

- Never use non-ASCII characters - in source code, code comments, commit
  messages, or markdown (no unicode arrows, em dashes, curly quotes, etc. --
  plain ASCII only).
- In .md files, fill prose lines out to the full 80 columns - do not break
  early at ~70. My editor re-flows paragraphs at 80, so short-wrapped text
  makes my edits churn far more lines than intended. This applies to markdown
  prose only, NOT to code comments (those keep the surrounding file's width),
  and NOT to markdown tables - let a table row run past 80 if it needs to,
  since wrapping a row breaks the table.
- never use the words 'pins' or 'pinned'


# Notes
