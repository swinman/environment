# environment

personal dotfiles, aliases, helpers, configurations and setup scripts.

## preferences

- linux over mac / windows
- vim as the editor
- git, python, c, sh, vhdl
- keyboard over mouse
- tabbed over typed
- cli over gui
- ascii over unicode
- dark over light colorscheme
- cterm colors over gui colors


## Read this first

Much of this repo is out of date. It accumulated across years of Ubuntu
desktops, and plenty of it describes a way of working that has since been
replaced by better norms - global `PYTHONPATH` instead of per-project venvs,
hand-rolled `apt-get` lists, `pathogen` instead of vim's native package
support, X11 assumptions that no longer hold anywhere.

Two things follow from that:

- **`setup/all_config.sh` should not be trusted as a whole.** Do not run it
  end-to-end expecting a working machine. Read the individual
  `setup/config_*.sh` script you actually want and run that. The mac path is
  deliberately built up one script at a time for this reason (see "Running it"
  below).
- **Do not assume something written for ubuntu is still wanted on ubuntu.**
  Age is not endorsement. Several scripts here install things that are no
  longer used at all, and being linux-only is not evidence that a script is
  current - only that nobody has revisited it.

The parts worth keeping are mostly the ones that encode hard-won detail rather
than installation steps: see "What is load-bearing" below.

## How it is wired

The setup scripts are in `setup/`. Everything they put into place - `_vimrc`,
`_aliases`, `colorvim/`, `after_vim/`, the udev rules - stays at the repo root,
which is what `$ENVDIR` means throughout. A script's own directory is
`$SETUPDIR`, and `$ENVDIR` is its parent.

`config_shell.sh` writes a bracketed block into the login shell's rc file
(`~/.zshrc` on mac, `~/.bashrc` on linux), and rewrites that block in place on
every run rather than appending duplicates:

    ##### START DO NOT EDIT BETWEEN THESE BRACKETS #####
    export OS=mac
    export ENVDIR="/Users/you/software/environment"
    ...
    if [ -f $ENVDIR/_aliases ]; then
        . $ENVDIR/_aliases
    fi
    ##### END DO NOT EDIT BETWEEN THESE BRACKETS #####

- `$OS` is `mac` or `linux`, auto-detected from `uname` when unset. Every
  platform branch in the repo tests it.
- `$ENVDIR` is this checkout. Prefer it for any new path. It replaced
  `${BASH_SOURCE[0]}` path derivation, which is bash-only and silently
  expanded to nothing under zsh.
- `$softwaredir` and `$toolsdir` still exist because roughly a dozen files
  read them, but they are legacy. `$softwaredir` existed largely to put
  `~/software` on `PYTHONPATH`; use a venv instead - `~/.venvs/dev` is
  activated by every interactive shell, and `uv pip install -e <checkout>`
  puts a tree on the path properly.
- Files prefixed with `_` are symlinked or sourced into place rather than used
  from `$HOME` directly: `_vimrc`, `_aliases`, `_spellvim`, `_claude_CLAUDE.md`,
  `_claude_settings.json`.
- `_aliases` is one shell-agnostic file for both bash and zsh. Shell-specific
  parts are guarded on `$ZSH_VERSION`, platform-specific parts on `$OS`. Note
  that a runtime guard does not stop the other shell from *parsing* the block,
  so zsh-only syntax inside a `$ZSH_VERSION` test must still be valid bash.
- The prompt is the exception to that: `_prompt_zsh` and `_prompt_bash` are
  separate files, sourced by `_aliases` according to the shell, because each
  needs syntax the other cannot parse. Both draw the same two-line shape and
  the same colors.
- `_completion_zsh` is split out for the same reason and has no bash
  counterpart, since `zstyle`, `bindkey` and `${terminfo[...]}` have no
  readline equivalent worth maintaining.

## Running it

    export OS=mac        # or linux, or let config_shell.sh detect it
    ./setup/all_config.sh

On mac this runs `config_shell.sh` and `config_mac.sh` and stops. Everything
past that point in `all_config.sh` is `apt-get` based, so mac does not fall
through to it. Add scripts to the mac block as each one is ported.

On linux it runs the historical full sequence. That sequence is the part this
README is warning about.

Individual scripts can be run directly and are written to be re-runnable:
rc-file edits are guarded or rewritten in place, and `mkdir` calls use `-p`.

Every run appends to `setup/log.log` - a full run and a single script run land
in the same file, each bracketed by a start and end line carrying the time and
the exit status. It is untracked, and it is what to hand over when a step
fails: the failure is usually thousands of lines of `apt-get` above the prompt
you are looking at.

## What is load-bearing

- `_vimrc` and `colorvim/colors/` - `storm` (dark) and `summer` (light),
  toggled with F3. `storm` carries both `gui` and 256-color `cterm` values;
  `summer`'s `cterm` values do not match its `gui` intent and only look right
  in gvim.
- `_aliases` - the language-scoped grep helpers (`pygrep`, `cgrep`, `vgrep`,
  ...) and git shorthands.
- `_prompt_zsh` / `_prompt_bash` - two-line prompt showing venv, host,
  truncated path and git branch, with the command line itself starting at
  column 0. Colors are taken from `storm.vim` so the shell and vim agree.
- `_completion_zsh` - completion behaviour (`rehash` so newly installed
  commands complete without a manual one, `special-dirs` so `..<TAB>` becomes
  `../`), Home/End bindings, and a `clear-screen` that scrolls into the
  scrollback buffer rather than erasing the screen the way Terminal.app
  otherwise does. The Home/End half only fires once the emulator sends
  something for those keys, which under Terminal.app takes the profile mapping
  written by `config_mac.sh`'s `config_terminal_keys`.
- `gen_completions.sh` - run by hand to regenerate `~/.zsh/completions.zsh`
  from whatever is installed in the active venv. Uses click's own completion
  protocol where a tool supports it and scrapes `--help` where it does not.
- `miniterm_wrapper.py` - serial console wrapper with port collapsing.
- `helpers/` - small single-purpose scripts (`math.sh`, `tepoc.sh`,
  `colordump.sh`, `grab_headers.sh`).
- `tsize` / `viq` / `vidq` in `_aliases` - resize the terminal window with one
  XTWINOPS escape, which works on mac and linux and over ssh.
- `_claude_*` - Claude Code settings and global preferences, symlinked into
  `~/.claude` by `config_claude.sh`.

## Status by file

Ported and exercised on mac:

| file | notes |
| --- | --- |
| `setup/config_shell.sh` | rc block, `$OS` detection, `$ENVDIR` |
| `setup/config_mac.sh` | brew list, brew ahead of `/usr/bin` in `PATH`, GNU tools ahead of BSD, ARM toolchain cask, Terminal.app Home/End mapping |
| `setup/config_claude.sh` | installs Claude Code, symlinks `_claude_*` |
| `setup/config_git.sh` | git config, then `config_ssh`; the git install itself belongs to `config_mac.sh` |
| `setup/config_vim.sh` | native `pack/plugins/start`, no pathogen, plugins via `clone_or_pull` |
| `setup/config_python.sh` | one shared venv activated by the rc block, no system `pip` |
| `_aliases` | mac branches for `vs`, `tdmesg`, screen recording, prompt |
| `setup/config_latex.sh` | MacTeX without the GUI apps, and a `~/Library/texmf` link to the standalone latex checkout |

Everything in that table is called from the mac branch of `setup/all_config.sh`.
`config_latex.sh` runs only when the up-front question is answered `y`, because
the full TeX Live it installs is several GB.

Not ported, and not going to be:

| file | why |
| --- | --- |
| `setup/config_arm.sh` | the `gcc-arm-embedded` cask, `openocd` and `segger-jlink` are in `config_mac.sh` already |
| `setup/config_fpga.sh` | no macOS build of iCEcube2 exists, and the CLI flow is x86 Linux ELF with node-locked licensing. VHDL compiles remotely instead; `fpga_config.sh` is already a no-op on mac. See `TODO.md` |
| `setup/config_udev.sh` | linux device rules, no mac equivalent |

Believed unused:

| file | notes |
| --- | --- |
| `setup/config_raspi.sh` | not used any more; near-copy of old `config_bash.sh` |
| `setup/config_windows.sh` | unaudited |

See `TODO.md` for the specific per-file porting notes, the remote VHDL build
plan, and the `termguicolors` change that would make vim and the shell prompt
render from the same color values.
