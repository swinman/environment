#!/bin/sh
#
# config_python.sh - the default python environment.
#
# One venv, activated by every interactive shell, holding a small standing
# toolset.  config_shell.sh writes the activation into its bracketed rc block.
#
# Project dependencies do NOT belong here.  Those are declared in each
# project's requirements or pyproject and installed deliberately, either into
# this venv or into a per-project one.  What lives here is only the handful of
# tools wanted regardless of what is being worked on.
#
# This replaces a version that installed twenty-odd packages with
# `sudo -H pip3 install` directly onto the system python, along with python2
# handling, cx-freeze and a page of Windows download links.  Installing onto a
# system interpreter is the thing this venv exists to prevent, and per-project
# requirements files cover what the long package list used to.
#
# NOTE : Symbol not found: _XML_Set.. is a brew python3.14 precompiled problem
# % brew reinstall --build-from-source python@3.14
# wll compiles against your local SDK stub, so pyexpat never references the
# missing symbol. Fixes it today; costs a long build, and a future brew upgrade
# can re-pour the bad bottle and undo it.
#
# Deliberately generic - nothing site-specific belongs in this file.

ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)}
. "$ENVDIR/config_common.sh"

# Keep VENVDIR in sync with the activation that config_shell.sh writes into the
# rc block.  Override either to build somewhere else, e.g.
#   VENVDIR=~/.venvs/other ./config_python.sh
VENVDIR=${VENVDIR:-$HOME/.venvs/dev}
VENVPY=${VENVPY:-3.12}

# --clean rebuilds from scratch rather than adding to what is already there.
# Everything installed into the venv is lost, so it is a flag rather than the
# default: the common case is re-running this to pick up a new base package.
CLEAN=${CLEAN:-0}
for _arg in "$@"; do
    case "$_arg" in
        --clean) CLEAN=1 ;;
        -h | --help)
            echo "usage: config_python.sh [--clean]"
            echo "  --clean   remove $VENVDIR first, then rebuild"
            exit 0
            ;;
        *)
            echo "unknown argument: $_arg" >&2
            echo "usage: config_python.sh [--clean]" >&2
            exit 1
            ;;
    esac
done

# Tools wanted whatever the project is.
#
# pyserial, not serial: both exist on PyPI and are unrelated.  pyserial is the
# one providing `import serial`, and it is what miniterm_wrapper.py needs.
#
# pandas is deliberately absent.  It arrives as a dependency of other things,
# and pinning it here would only fight those pins.
#
# jupyterlab and notebook rather than the `jupyter` metapackage.  notebook 7 is
# built on jupyterlab, so the pair gives both the lab and the notebook
# interface, while the metapackage would additionally pull qtconsole,
# jupyter-console and nbconvert.
BASE_PKGS=${BASE_PKGS:-"ipython numpy scipy matplotlib jupyterlab notebook snakeviz pyserial"}

# Tools that belong on PATH rather than in the venv.  `uv tool install` gives
# each its own isolated environment and links it into ~/.local/bin, so they
# resolve whatever venv is active - or none at all.
#
# ~/.local/bin reaches PATH via ~/.profile, which the rc block does not touch
# and only a login shell reads.  Nothing here adds it, so a tool installed
# below can be missing from a shell that started without it.
#
# ruff is what the project repos lint with: ruff.toml in mfg, ralgs and rlab,
# and astral-sh/ruff-pre-commit in eight repos' pre-commit config.  pre-commit
# manages its own pinned copy, so this one is for editing rather than for the
# hooks: _vimrc points ALE at it, and it is what `ruff check` on the command
# line resolves to.
UV_TOOLS=${UV_TOOLS:-"ruff"}

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #

# Everything below needs uv, so it is installed rather than left to the reader.
# Printing instructions and returning meant a run from all_config.sh built no
# venv at all and carried on, and the rc block's activation is guarded on the
# venv existing, so the only symptom was a shell with no (dev) in the prompt.
#
# No apt branch on linux: uv is not in the noble archive, so it could only ever
# fall through to the installer below.
check_uv() {
    if command -v uv >/dev/null 2>&1; then
        echo "uv present: $(uv --version)"
        return 0
    fi
    echo "uv not found, installing"
    if [ "$OS" = "mac" ]; then
        brew install uv
    else
        command -v curl >/dev/null 2>&1 || sudo apt-get install curl -y
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    # The installer links into ~/.local/bin.  ~/.profile is what puts that on
    # PATH, and only a login shell reads it, so a shell that started without it
    # will not find uv however the install went.
    if ! command -v uv >/dev/null 2>&1 && [ -x "$HOME/.local/bin/uv" ]; then
        PATH="$HOME/.local/bin:$PATH"
        export PATH
    fi
    if command -v uv >/dev/null 2>&1; then
        echo "uv installed: $(uv --version)"
        return 0
    fi
    echo "  WARNING: uv install failed, venv not built" >&2
    return 1
}

clean_venv() {
    [ "$CLEAN" = 1 ] || return 0
    [ -e "$VENVDIR" ] || return 0
    # A mis-set VENVDIR would otherwise take a real directory with it, so only
    # a tree that actually looks like a venv is removed.
    if [ ! -f "$VENVDIR/pyvenv.cfg" ]; then
        echo "Refusing to clean $VENVDIR" >&2
        echo "  no pyvenv.cfg there - that is not a venv" >&2
        return 1
    fi
    echo "Removing $VENVDIR"
    rm -rf "$VENVDIR"
}

make_venv() {
    if [ -f "$VENVDIR/bin/activate" ]; then
        echo "venv already present at $VENVDIR"
        echo "  $("$VENVDIR/bin/python" -V 2>&1)"
        return 0
    fi
    echo "Creating venv at $VENVDIR (python $VENVPY)"
    # --seed installs pip and setuptools.  Plain `uv venv` creates an
    # environment with no pip at all, and this venv exists to be where a
    # `pip install` can land.
    #
    # only-managed keeps PATH out of the interpreter search.  Left open, uv
    # falls through to the first matching python3 on PATH - a conda env, a
    # pyenv shim - and pyvenv.cfg then borrows that environment's stdlib, so
    # the venv dies whenever the environment does.  Restricted to managed
    # interpreters, uv downloads its own (once, ~20MB) into
    # ~/.local/share/uv/python, which nothing but uv touches, so the base
    # does not depend on any particular system python.
    mkdir -p "$(dirname "$VENVDIR")"
    UV_PYTHON_PREFERENCE=only-managed uv venv --seed --python "$VENVPY" "$VENVDIR"
}

install_base_packages() {
    echo "Installing base packages into $VENVDIR"
    echo "  $BASE_PKGS"
    # uv pip installs into the venv named by VIRTUAL_ENV, so point it at the
    # target rather than relying on whatever happens to be active.  This works
    # without the venv being activated, which matters when the script runs from
    # all_config.sh before any new shell has started.
    VIRTUAL_ENV="$VENVDIR" uv pip install $BASE_PKGS
}

install_uv_tools() {
    echo "Installing standalone tools"
    for _t in $UV_TOOLS; do
        echo "  $_t"
        # --quiet still reports failures; without it every install reprints
        # the resolution summary.
        uv tool install --quiet "$_t" ||
            echo "  WARNING: uv tool install $_t failed"
    done
}

# --------------------- SETUP SCRIPT --------------------- #

echo "=================== config_python.sh ==================="

rc=0
if clean_venv && check_uv && make_venv; then
    install_base_packages
    install_uv_tools
    echo
    echo "New interactive shells activate this automatically, unless a venv is"
    echo "already active - an explicitly chosen project venv is never replaced."
    echo
    echo "Add project packages with the venv active:"
    echo "  uv pip install -e <path-to-checkout>"
    echo
    echo "Rebuild it from scratch with:"
    echo "  $ENVDIR/config_python.sh --clean"
else
    # Exits non-zero so a caller can tell that no venv was built.  Silence here
    # is what let a failed run pass for a successful one.
    echo "  WARNING: no venv at $VENVDIR" >&2
    rc=1
fi

echo "============== END: config_python.sh ==================="
exit $rc
