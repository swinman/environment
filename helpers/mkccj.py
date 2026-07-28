#!/usr/bin/env python3
"""Generate compile_commands.json for a makefile-driven build.

clangd needs the exact command each file is compiled with - the cross
compiler, the target flags, every -D and every include path.  Given that, it
lints firmware with the same view the compiler has, resolves the live branch
of each #ifdef, and answers go-to-definition and find-references properly.
Given nothing, it guesses with the host compiler and reports every target
header as missing.

`bear -- make` is the usual way to produce that file, but it works by
intercepting an actual build, so it needs the build to run and to succeed.
`make -n` prints the same commands without running them, which is faster and
works on a tree that does not currently build.

WHICH BUILD CONFIGURATION GETS CAPTURED

A compile_commands.json describes one configuration.  These trees select a
board and a feature set through make variables - MODEL picks the directory
under src/conf/boards, and flags like STOPSEN_DEVMODE turn into -D - so code
guarded by a variant you did not build reads as dead in the editor, correctly.

Arguments are passed through to make, so the configuration is chosen the same
way the build chooses it:

    mkccj.py                          # whatever a bare make would build
    mkccj.py MODEL=tf96               # a different board
    mkccj.py MODEL=tf96 STOPSEN_DEVMODE=true

Where the build records its own flags in .cppflags, the captured defines are
checked against it, so a database that does not match the last real build says
so rather than quietly describing something else.
"""

import argparse
import json
import shlex
import subprocess
import sys
from pathlib import Path

# Dependency generation writes .d files alongside the objects.  clangd has no
# use for them and the -MT arguments name object files that need not exist.
DROP_WITH_ARG = {"-MF", "-MT", "-MQ"}
DROP_ALONE = {"-MD", "-MP", "-MMD"}

# Defines worth echoing back, because they are the ones that select a variant.
VARIANT_HINTS = ("MODEL", "HW_VERSION", "FW_VERSION", "BOARD", "DEVMODE")

# Changes on every commit, so a difference here says nothing about whether two
# builds share a configuration.
VOLATILE = {"GIT_HASH"}


def is_compile_line(argv):
    """True for a line that compiles one C source into an object."""
    if not argv or "-c" not in argv:
        return False
    driver = Path(argv[0]).name
    if not driver.endswith(("gcc", "g++", "clang", "clang++", "cc")):
        return False
    return any(a.endswith(".c") for a in argv)


def clean(argv):
    """Drop the dependency-generation flags, keeping everything else."""
    out, skip = [], False
    for arg in argv:
        if skip:
            skip = False
            continue
        if arg in DROP_WITH_ARG:
            skip = True
            continue
        if arg in DROP_ALONE:
            continue
        out.append(arg)
    return out


def defines(argv):
    """The -D flags of a command as {name: value}.

    Values are unquoted, because the same define reaches this from two
    directions - the shell-split compile line and the .cppflags file the build
    echoes - and MODEL="ns32" against MODEL=ns32 is not a difference worth
    reporting.
    """
    found, take_next = {}, False
    for arg in argv:
        item = None
        if take_next:
            item, take_next = arg, False
        elif arg == "-D":
            take_next = True
        elif arg.startswith("-D"):
            item = arg[2:]
        if item:
            name, _, value = item.partition("=")
            if name:
                found[name] = value.strip("'\"")
    return found


def recorded_defines(root):
    """The -D set the last real build used, if the tree records one."""
    cppflags = root / ".cppflags"
    if not cppflags.is_file():
        return None
    return defines(shlex.split(cppflags.read_text()))


def main():
    parser = argparse.ArgumentParser(
        description="Write compile_commands.json from `make -n` output.",
        epilog="Extra arguments are passed to make, so the build "
               "configuration is selected exactly as the build selects it.",
    )
    parser.add_argument("-C", "--directory", default=".",
                        help="project root to run make in (default: cwd)")
    parser.add_argument("-o", "--output", default="compile_commands.json",
                        help="output file, relative to the project root")
    parser.add_argument("--timeout", type=int, default=300,
                        help="seconds to allow make -n (default: 300)")
    parser.add_argument("make_args", nargs=argparse.REMAINDER,
                        help="arguments passed through to make, e.g. MODEL=tf96")
    args = parser.parse_args()

    root = Path(args.directory).resolve()
    if not (root / "Makefile").is_file():
        sys.exit(f"no Makefile in {root}")

    make_args = [a for a in args.make_args if a != "--"]
    cmd = ["make", "-n"] + make_args
    print(f"running: {' '.join(cmd)}")
    try:
        proc = subprocess.run(cmd, cwd=root, capture_output=True, text=True,
                              timeout=args.timeout)
    except subprocess.TimeoutExpired:
        sys.exit(f"make -n did not finish within {args.timeout}s")

    # A non-zero status is not fatal: make often stops at a recipe that needs a
    # file the dry run did not create, after printing the compile lines wanted.
    entries, seen = [], set()
    for line in proc.stdout.splitlines():
        try:
            argv = shlex.split(line)
        except ValueError:
            continue
        if not is_compile_line(argv):
            continue
        argv = clean(argv)
        source = next(a for a in argv if a.endswith(".c"))
        path = (root / source).resolve()
        if path in seen:
            continue
        seen.add(path)
        entries.append({"directory": str(root), "file": str(path),
                        "arguments": argv})

    if not entries:
        print("no compile commands found in the make -n output", file=sys.stderr)
        if proc.returncode != 0:
            print(f"make exited {proc.returncode}:", file=sys.stderr)
            print("\n".join(proc.stderr.splitlines()[-5:]), file=sys.stderr)
        sys.exit(1)

    out = root / args.output
    out.write_text(json.dumps(entries, indent=2) + "\n")
    print(f"{len(entries)} entries -> {out}")
    print(f"compiler:  {entries[0]['arguments'][0]}")

    captured = defines(entries[0]["arguments"])
    variant = sorted(n for n in captured
                     if any(h in n for h in VARIANT_HINTS))
    if variant:
        print("captured configuration:")
        for name in variant:
            print(f"  {name}={captured[name]}")

    # The build writes .cppflags on every run, so it is the record of what was
    # last actually built.  A mismatch means this database describes some other
    # configuration, which is exactly the case where the editor greys out live
    # code and nothing on screen explains why.
    #
    # Only names present in both are compared.  .cppflags holds CPPFLAGS alone,
    # while the compile line also carries defines the makefile adds elsewhere,
    # so a name missing from one side is not evidence of a different build.
    last = recorded_defines(root)
    if last is None:
        return
    differing = sorted(n for n in set(last) & set(captured)
                       if last[n] != captured[n] and n not in VOLATILE)
    dropped = sorted(n for n in set(last) - set(captured) if n not in VOLATILE)
    if not differing and not dropped:
        print("matches .cppflags: this is the configuration last built")
        return
    print("\nWARNING: does not match .cppflags, the last build's flags.")
    for name in differing:
        print(f"  {name}: last built {last[name]!r}, captured "
              f"{captured[name]!r}")
    for name in dropped:
        print(f"  {name}={last[name]} was in the last build, absent here")
    print("re-run with the same make variables to describe that build.")


if __name__ == "__main__":
    main()
