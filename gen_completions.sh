#!/bin/sh
#
# gen_completions.sh - generate zsh completions for the console scripts in a
# virtualenv (or any bin directory) and write them as one sourceable file.
#
# Run it by hand after installing or upgrading tools.  Nothing runs it
# automatically: it executes every command it scans (see below), which is far
# too slow and too side-effecting for shell startup.  _completion_zsh sources
# the file it produces, so a new shell picks up the result.
#
# The name deliberately starts with a letter no other script in this directory
# uses, so `$ENVDIR/g<TAB>` completes it outright.
#
# Usage:
#   ./gen_completions.sh                  scan $VIRTUAL_ENV/bin, else the
#                                         default venv ~/.venvs/dev/bin
#   ./gen_completions.sh DIR [DIR ...]    scan the given bin directories
#   ./gen_completions.sh -o FILE [DIR]    write somewhere other than the
#                                         default output path
#   ./gen_completions.sh -v               also report what was skipped and why
#
# Two sources of completion are used, best first:
#
#   click   Tools built on click implement a completion protocol: run one with
#           _<NAME>_COMPLETE=zsh_source in the environment and it prints its
#           own zsh completion function instead of doing any work.  That is
#           exact - subcommands, per-subcommand options, value choices.
#
#   --help  Everything else.  argparse has no completion protocol at all, and
#           argcomplete only works for tools that call it themselves, which
#           none of these do.  So the fallback runs `<cmd> --help` and scrapes
#           the option table out of it.  That yields flag completion with the
#           help text as the description, and nothing else: no subcommands, no
#           values, no argument types.  It is a real step down from click, but
#           it is the difference between some completion and none, and on a
#           typical venv it covers almost everything.
#
# Both routes execute the command.  --help is safe for anything built on
# argparse or click, since both print and exit before main() does anything,
# but a tool that does work at import time will do that work here.  Each run
# gets a timeout and /dev/null on stdin; anything that hangs, crashes or
# prints nothing usable is skipped rather than turned into a broken
# completion.

set -u

ENVDIR_DEFAULT_VENV="$HOME/.venvs/dev/bin"
OUT="${GEN_COMPLETIONS_OUT:-$HOME/.zsh/completions.zsh}"
VERBOSE=0

while [ $# -gt 0 ]; do
    case "$1" in
        -o) shift; [ $# -gt 0 ] || { echo "gen_completions.sh: -o needs a path" >&2; exit 2; }; OUT="$1"; shift ;;
        -v) VERBOSE=1; shift ;;
        -h|--help) sed -n '2,/^set -u/p' "$0" | sed 's/^# \{0,1\}//; $d'; exit 0 ;;
        --) shift; break ;;
        -*) echo "gen_completions.sh: unknown option $1" >&2; exit 2 ;;
        *)  break ;;
    esac
done

if [ $# -gt 0 ]; then
    DIRS="$*"
elif [ -n "${VIRTUAL_ENV:-}" ] && [ -d "$VIRTUAL_ENV/bin" ]; then
    DIRS="$VIRTUAL_ENV/bin"
elif [ -d "$ENVDIR_DEFAULT_VENV" ]; then
    DIRS="$ENVDIR_DEFAULT_VENV"
else
    echo "gen_completions.sh: no venv found; pass a bin directory" >&2
    exit 1
fi

for d in $DIRS; do
    if [ ! -d "$d" ]; then
        echo "gen_completions.sh: not a directory: $d" >&2
        exit 1
    fi
done

command -v python3 >/dev/null 2>&1 || {
    echo "gen_completions.sh: python3 not on PATH" >&2
    exit 1
}

mkdir -p "$(dirname "$OUT")" || exit 1

GEN_COMPLETIONS_VERBOSE=$VERBOSE \
GEN_COMPLETIONS_OUTFILE="$OUT" \
python3 - $DIRS <<'PYEOF'
"""Scrape zsh completions out of the console scripts in a bin directory."""

import concurrent.futures
import os
import pathlib
import re
import subprocess
import sys
import time

TIMEOUT = 15
WORKERS = 8

OUT = pathlib.Path(os.environ["GEN_COMPLETIONS_OUTFILE"])
VERBOSE = os.environ.get("GEN_COMPLETIONS_VERBOSE") == "1"
DIRS = [pathlib.Path(d) for d in sys.argv[1:]]

# The venv's own machinery, not commands.  Everything else in bin is fair game.
SKIP_EXACT = {"python", "python3", "pythonw", "activate", "deactivate"}
SKIP_RE = re.compile(
    r"""^(
          python3\.\d+          # python3.12 and friends
        | (de)?activate([._].*)?   # activate.csh, activate_this.py, ...
        | Activate\.ps1
        )$""",
    re.VERBOSE,
)
# Shell fragments for other shells, and Windows leftovers.
SKIP_SUFFIX = (".bat", ".ps1", ".fish", ".csh", ".nu", ".exe")


def candidates():
    """Executable console scripts across every scanned directory, deduped."""
    seen = set()
    out = []
    for d in DIRS:
        for p in sorted(d.iterdir()):
            name = p.name
            if name in seen:
                continue
            if not p.is_file() or not os.access(p, os.X_OK):
                continue
            if name.startswith(".") or name in SKIP_EXACT or SKIP_RE.match(name):
                continue
            if name.endswith(SKIP_SUFFIX):
                continue
            seen.add(name)
            out.append(p)
    return out


def run(path, args, extra_env=None):
    env = dict(os.environ)
    if extra_env:
        env.update(extra_env)
    # A tool that reads stdin would otherwise block until the timeout.
    try:
        return subprocess.run(
            [str(path)] + args,
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
            errors="replace",
            timeout=TIMEOUT,
            env=env,
        )
    except (subprocess.TimeoutExpired, OSError, ValueError):
        return None


def zsh_ident(name):
    return re.sub(r"[^A-Za-z0-9_]", "_", name)


def clean_desc(text):
    """Reduce a help string to something safe inside a '...[desc]' spec.

    Escaping would preserve more, but every character below has a meaning to
    _arguments, and a spec that fails to parse breaks completion for the whole
    command.  Substituting is lossy and always valid, which is the better
    trade for generated output nobody is going to read.
    """
    text = re.sub(r"\s+", " ", text).strip()
    # Some help tables write "--opt  : str, optional", so the description
    # arrives with the separator still attached.  Drop it before ':' becomes
    # a dash below, or every one of them reads " - str, optional".
    text = text.lstrip(":").strip()
    text = text.replace("\\", "")
    text = text.replace("'", "")
    text = text.replace("[", "(").replace("]", ")")
    text = text.replace(":", " -")
    if len(text) > 90:
        text = text[:87].rstrip() + "..."
    return text


# One option entry in a help table: leading whitespace, then a flag.  Anything
# starting with '[' is a wrapped usage line, and is left alone by the leading
# '-' requirement.
OPT_START = re.compile(r"^[ \t]+(-{1,2}[A-Za-z0-9?].*)$")
# '-o OUT', '--out=OUT', '--out OUT' or a bare '--flag'.
OPT_TOKEN = re.compile(r"^(--?[A-Za-z0-9?][-A-Za-z0-9_]*)(?:[ =](.+))?$")
# An indented line with no flag on it, i.e. a wrapped description.
CONT = re.compile(r"^[ \t]{6,}(\S.*)$")


def parse_help(text):
    """Pull (flag, metavar, description) out of an argparse/click help table."""
    found = {}
    order = []
    pending = None  # flags still waiting for a description on a later line

    def commit(flags, desc):
        for flag, metavar in flags:
            if flag in found:
                continue
            found[flag] = (metavar, desc)
            order.append(flag)

    for line in text.splitlines():
        if line.lower().startswith("usage"):
            pending = None
            continue
        m = OPT_START.match(line)
        if m:
            if pending:
                commit(pending, "")
                pending = None
            rest = m.group(1)
            # Two or more spaces separate the option column from its
            # description; one space is still inside the option column.
            parts = re.split(r"\s{2,}", rest, maxsplit=1)
            optpart = parts[0]
            desc = parts[1] if len(parts) > 1 else ""
            flags = []
            for tok in re.split(r",\s*", optpart):
                tm = OPT_TOKEN.match(tok.strip())
                if not tm:
                    continue
                metavar = tm.group(2)
                if metavar:
                    metavar = metavar.strip().strip("{}<>")
                    # A choice list or a long metavar is not worth showing.
                    if len(metavar) > 24 or "," in metavar:
                        metavar = "arg"
                flags.append((tm.group(1), metavar))
            if not flags:
                continue
            if desc:
                commit(flags, desc)
            else:
                pending = flags
            continue
        if pending:
            cm = CONT.match(line)
            if cm:
                commit(pending, cm.group(1))
            else:
                commit(pending, "")
            pending = None
    if pending:
        commit(pending, "")
    return [(f, found[f][0], found[f][1]) for f in order]


def spec_lines(options):
    out = []
    for flag, metavar, desc in options:
        desc = clean_desc(desc)
        spec = flag + "[" + desc + "]" if desc else flag
        if metavar:
            spec += ":" + clean_desc(metavar) + ":"
        out.append("'" + spec + "'")
    return out


def click_env_var(name):
    return "_" + re.sub(r"[^A-Za-z0-9]", "_", name).upper() + "_COMPLETE"


def probe(path):
    """Return (name, kind, body, note) for one command."""
    name = path.name
    r = run(path, ["--help"])
    if r is None:
        return name, None, None, "no response to --help (timeout or exec error)"
    help_text = (r.stdout or "") + "\n" + (r.stderr or "")
    if not help_text.strip():
        return name, None, None, "--help printed nothing"

    # click's usage line always carries a literal [OPTIONS], which is a cheap
    # signal and avoids running the completion protocol against tools that
    # would just execute instead of honouring it.
    if re.search(r"^\s*Usage:.*\[OPTIONS\]", help_text, re.M):
        c = run(path, [], {click_env_var(name): "zsh_source"})
        if c is not None and c.stdout and "compdef" in c.stdout:
            return name, "click", c.stdout.rstrip("\n"), None

    options = parse_help(help_text)
    if not options:
        return name, None, None, "no options found in --help output"
    fn = "_gen_" + zsh_ident(name)
    specs = spec_lines(options)
    body = [fn + "() {", "    _arguments -s -S \\"]
    body += ["        " + s + " \\" for s in specs]
    body.append("        '*:file:_files'")
    body.append("}")
    body.append("compdef " + fn + " " + name)
    return name, "help", "\n".join(body), None


def main():
    cmds = candidates()
    if not cmds:
        print("gen_completions.sh: no console scripts found", file=sys.stderr)
        return 1

    results = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as pool:
        for name, kind, body, note in pool.map(probe, cmds):
            results[name] = (kind, body, note)

    click_n = [n for n in results if results[n][0] == "click"]
    help_n = [n for n in results if results[n][0] == "help"]
    skipped = [(n, results[n][2]) for n in results if results[n][0] is None]

    stamp = time.strftime("%Y-%m-%d %H:%M:%S")
    lines = [
        "# Generated by gen_completions.sh -- do not edit, it is overwritten.",
        "# Regenerate:  $ENVDIR/gen_completions.sh",
        "#",
        "# Generated " + stamp,
        "# Scanned:   " + ", ".join(str(d) for d in DIRS),
        "# Commands:  " + str(len(click_n)) + " from click, "
        + str(len(help_n)) + " scraped from --help, "
        + str(len(skipped)) + " skipped",
        "#",
        "# Sourced by _completion_zsh, which is why every entry ends in an",
        "# explicit compdef rather than relying on $fpath: compinit has",
        "# already run by then.",
        "",
    ]
    for name in sorted(click_n):
        lines.append("# ---- " + name + " (click) ----")
        lines.append(results[name][1])
        lines.append("")
    for name in sorted(help_n):
        lines.append("# ---- " + name + " (scraped from --help) ----")
        lines.append(results[name][1])
        lines.append("")

    tmp = OUT.with_name(OUT.name + ".tmp")
    tmp.write_text("\n".join(lines) + "\n")
    tmp.replace(OUT)

    print(f"wrote {OUT}")
    print(f"  click   {len(click_n):3d}  {' '.join(sorted(click_n))}")
    print(f"  --help  {len(help_n):3d}")
    print(f"  skipped {len(skipped):3d}")
    if VERBOSE:
        for name, note in sorted(skipped):
            print(f"    {name:<28} {note}")
    return 0


sys.exit(main())
PYEOF
