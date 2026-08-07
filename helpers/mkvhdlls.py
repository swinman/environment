#!/usr/bin/env python3
"""Generate vhdl_ls.toml for a VHDL project.

vhdl_ls needs to know which files make up which library.  Given that, it
resolves entity and component references across files, and its diagnostics and
semantic highlighting describe the design as it is actually elaborated.  Given
nothing, it still starts and still highlights, but logs "Library mapping is
unknown", treats every file as outside the project, and its analysis may be
wrong in ways nothing on screen distinguishes from correct.

This is the VHDL counterpart to the compile_commands.json that clangd wants for
C, and the failure it guards against is the same one: an editor quietly
describing something other than the code in front of you.  The C side is not
here - liblusam's mk/ccdb.py writes it from the stamps the firmware build
already records, and runs at postbuild so it cannot go stale.

ONE LIBRARY, NOT ONE PER DIRECTORY

Everything discovered lands in a single library.  VHDL resolves an unqualified
reference through `work`, which names whichever library the current unit is
being compiled into, so a testbench in simulation/ referring to an entity in
fpga/ only works while both are the same library.  Splitting the tree by
directory would need every one of those references qualified with an explicit
library clause, which is not how these designs are written or synthesised.

`work` itself is rejected as a name here, because it is that alias rather than
a library, so the default is `defaultlib`.

DIRECTORY GLOBS, NOT FILE LISTS

Each directory holding sources contributes a glob.  A file added later is then
picked up without regenerating, which matters because nothing prompts you to
re-run this - an omitted file does not error, it silently drops out of the
analysis.  For the same reason the globs are checked against the files that
were found, so a source in a layout the globs do not describe is reported
rather than dropped.

Hand edits are expected for third-party or vendor sources, which want their
own library with `is_third_party = true` to keep their warnings out of yours.
An existing file is therefore never overwritten without --force.
"""

import argparse
import sys
from pathlib import Path, PurePath

VHDL_SUFFIXES = (".vhd", ".vhdl")

# Build output and tool state rather than sources.  iCEcube2 copies sources
# into its project directory, so a tree left in place would otherwise be
# analysed twice, once per copy, and every design unit would look duplicated.
SKIP_DIRS = {".git", ".svn", "build", "output", "obj", "sbt_backend",
             "proj_ice", "__pycache__"}


def find_sources(root, skip):
    """Every VHDL source under root, as paths relative to it."""
    found = []
    for path in sorted(root.rglob("*")):
        if path.suffix.lower() not in VHDL_SUFFIXES or not path.is_file():
            continue
        rel = path.relative_to(root)
        if any(part in skip for part in rel.parts[:-1]):
            continue
        found.append(rel)
    return found


def globs_for(files):
    """One glob per directory and suffix actually present.

    Keyed on both, because a directory holding .vhd and .vhdl needs a pattern
    for each - a single '*' would also sweep up unrelated files.
    """
    seen = {(f.parent, f.suffix) for f in files}
    out = []
    for parent, suffix in sorted(seen, key=lambda p: (str(p[0]), p[1])):
        prefix = "" if str(parent) == "." else f"{parent.as_posix()}/"
        out.append(f"{prefix}*{suffix}")
    return out


def uncovered(files, globs):
    """Sources no emitted glob matches.

    PurePath.match is used rather than fnmatch because '*' there does not
    cross a directory separator, which is the behaviour the toml globs have.
    """
    return [f for f in files
            if not any(PurePath(f.as_posix()).match(g) for g in globs)]


def render(library, globs, standard):
    lines = [f'standard = "{standard}"', "", "[libraries]"]
    lines.append(f"{library}.files = [")
    lines += [f"    '{g}'," for g in globs]
    lines.append("]")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(
        description="Write vhdl_ls.toml describing a VHDL project.",
    )
    parser.add_argument("-C", "--directory", default=".",
                        help="project root to scan (default: cwd)")
    parser.add_argument("-o", "--output", default="vhdl_ls.toml",
                        help="output file, relative to the project root")
    parser.add_argument("-l", "--library", default="defaultlib",
                        help="library name to put every source in "
                             "(default: defaultlib)")
    parser.add_argument("--standard", default="2008",
                        help="VHDL standard vhdl_ls analyses against "
                             "(default: 2008, which is also its own default)")
    parser.add_argument("--exclude", action="append", default=[],
                        metavar="DIR",
                        help="directory name to skip, repeatable; added to "
                             f"{', '.join(sorted(SKIP_DIRS))}")
    parser.add_argument("-f", "--force", action="store_true",
                        help="overwrite an existing file, discarding hand "
                             "edits such as third-party libraries")
    args = parser.parse_args()

    root = Path(args.directory).resolve()
    if not root.is_dir():
        sys.exit(f"not a directory: {root}")

    # vhdl_ls rejects this, and the message it gives does not say why, so say
    # it here where the name is being chosen.
    if args.library.lower() == "work":
        sys.exit("'work' is not a library name - it is the alias for whichever"
                 " library a unit is compiled into. Use --library defaultlib.")

    out = root / args.output
    if out.exists() and not args.force:
        sys.exit(f"{out} exists; pass --force to overwrite it")

    files = find_sources(root, SKIP_DIRS | set(args.exclude))
    if not files:
        sys.exit(f"no {' or '.join(VHDL_SUFFIXES)} files under {root}")

    globs = globs_for(files)

    # A glob that describes none of the files found would mean this wrote a
    # config for a layout that is not there.
    missed = uncovered(files, globs)
    if missed:
        print("BUG: these sources match no generated pattern:",
              file=sys.stderr)
        for path in missed:
            print(f"  {path}", file=sys.stderr)
        sys.exit(1)

    out.write_text(render(args.library, globs, args.standard))

    dirs = sorted({f.parent.as_posix() for f in files})
    print(f"{len(files)} sources in {len(dirs)} directories -> {out}")
    print(f"library:   {args.library}")
    print(f"standard:  {args.standard}")
    for name in dirs:
        count = sum(1 for f in files if f.parent.as_posix() == name)
        print(f"  {name}: {count}")


if __name__ == "__main__":
    main()
