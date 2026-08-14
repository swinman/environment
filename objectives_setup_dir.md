# objectives_setup_dir

## Objectives

1. Move the machine-setup scripts into `setup/`, so `./setup/all_config.sh`
   works from the repo root and the root stops being a flat pile of scripts
   and dotfiles.
2. Log every setup run to `setup/log.log`, so a standalone run (the ones
   needing sudo, driven from a plain terminal rather than from a tool
   session) can be handed back verbatim when something fails.

## Scope

Moved: `all_config.sh` and the `config_*.sh` family.

Not moved, because `_aliases` sources them by `$ENVDIR/<name>` at runtime and
they are tools rather than setup: `fpga_config.sh` (`uctools`),
`vim_config.sh` (`vitags`), `shconf_maroon.sh`, `gen_completions.sh`, the
`.py` tools, `helpers/`, `snippits/`.

Data files stay at the repo root (`_vimrc`, `_aliases`, `_gitignore`,
`colorvim/`, `after_vim/`, `99-*.rules`), so `$ENVDIR` keeps meaning the repo
root and every `link_config` argument stays as it was.

## Todo

- [x] branch, `git mv` the fourteen scripts
- [x] `$SETUPDIR` / `$ENVDIR` preamble in each moved script
- [x] `start_log` in `config_common.sh`, called from each entry point
- [x] `setup/log.log` in `.gitignore`
- [x] README paths
- [ ] test `./setup/config_avr_arm.sh` and a full `./setup/all_config.sh`

## Journal

- `$ENVDIR` had been derived per script as `dirname $0`. After the move that
  points at `setup/`, one level below what `link_config` and the `_vimrc` /
  `_aliases` / `_gitignore` references expect. Each script now computes
  `$SETUPDIR` from `$0` and `$ENVDIR` as its parent, and sources
  `$SETUPDIR/config_common.sh`. An `$ENVDIR` already exported by the rc block
  still wins, as before.
- `all_config.sh` ran its steps as `./$1`, which required the caller's cwd to
  be the script's directory - `./setup/all_config.sh` would have failed on
  the first step. Steps now run as `$SETUPDIR/$1`.
- Logging re-execs through `tee -a`. The exit status is carried out of the
  pipe through a temp file rather than `PIPESTATUS`, which `/bin/sh` does not
  have and most of these scripts are `#!/bin/sh`. `$CONFIG_LOG` in the
  environment is the recursion guard, and it also keeps the child scripts
  `all_config.sh` spawns from opening a second `tee` - they inherit the pipe.
- `config_shell.sh` is sourced by `all_config.sh`, where a re-exec would
  restart `all_config.sh` itself. Its `start_log` call is guarded on `$0`
  ending in `config_shell.sh`, which is false in the sourced case.
- Log is append-with-banner: start line, end line with exit status, both
  timestamped. A standalone script run and a full run land in the same file
  in order.
- A log that cannot be written (root-owned from a `sudo ./setup/...` run, say)
  warns and the script continues unlogged, rather than failing the setup.
