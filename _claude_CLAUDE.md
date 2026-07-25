<!-- Symlinked to ~/.claude/CLAUDE.md by config_claude.sh, so these follow you
     to every machine.  Keep it machine-independent; per-repo rules belong in
     that repo's own CLAUDE.md. -->

# Global preferences

- NEVER start modifying files off an open-ended prompt. A message like
  "read the objectives file and let's continue closing things out" is a
  request to REVIEW and PROPOSE next steps - nothing more. Present the
  options, recommend one, and WAIT for an explicit go-ahead on a concrete
  action before touching any file, repo, or checkout. This has been
  violated before (2026-07-15: launched into merging lib branches when
  asked only to read objectives_cleanup.md). Do not do it again.
- Never recommend pushing a repo. Commit when asked, but leave pushing entirely
  to me.
- Never fast-forward merges: always `git merge --no-ff` so the feature branch
  stays a cohesive unit in history.
- Never use non-ASCII characters in commit messages or in code / code comments
  (no unicode arrows, em dashes, curly quotes, etc. -- plain ASCII only).
- In .md files, fill prose lines out to the full 80 columns - do not break
  early at ~70. My editor re-flows paragraphs at 80, so short-wrapped text
  makes my edits churn far more lines than intended. This applies to markdown
  prose only, NOT to code comments (those keep the surrounding file's width).
- for commit headers - DEFINITELY don't violate the 80 characters rule; in fact
  try to keep the first line of a commit under 50 characters
- In Python, format strings with f-strings (`f"{x}"`) - never C/printf `%`-style
  (`"%s" % x`) or `str.format()`. Use nested specs like `f"{x:>{width}}"` for
  alignment.
- Write code comments and docstrings in an impersonal voice. Never use first
  person (I/we/my/our) - state what the code does or why, not what the author
  wants. E.g. "The serial number is usually important" rather than "the thing
  I most want to see". Second person (you/your) is fine where it naturally
  addresses the reader or user, e.g. "the ports you care about".


# Notes

- If I forgot build tools (arm-non-eabi\* etc), then you need to
    `source ~/software/environment/fpga_config.sh` into workspace to get them
