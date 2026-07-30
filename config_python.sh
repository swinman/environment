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

# Tools wanted whatever the project is.
#
# pyserial, not serial: both exist on PyPI and are unrelated.  pyserial is the
# one providing `import serial`, and it is what miniterm_wrapper.py needs.
#
# pandas is deliberately absent.  It arrives as a dependency of other things,
# and pinning it here would only fight those pins.
BASE_PKGS=${BASE_PKGS:-"ipython numpy scipy snakeviz pyserial"}

# Tools that belong on PATH rather than in the venv.  `uv tool install` gives
# each its own isolated environment and links it into ~/.local/bin, which the
# rc block already puts on PATH, so they resolve whatever venv is active - or
# none at all.
#
# ruff is what the project repos lint with: ruff.toml in mfg, ralgs and rlab,
# and astral-sh/ruff-pre-commit in eight repos' pre-commit config.  pre-commit
# manages its own pinned copy, so this one is for editing rather than for the
# hooks: _vimrc points ALE at it, and it is what `ruff check` on the command
# line resolves to.
UV_TOOLS=${UV_TOOLS:-"ruff"}

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #

check_uv() {
    if command -v uv >/dev/null 2>&1; then
        echo "uv present: $(uv --version)"
        return 0
    fi
    echo "uv not found.  Install it, then re-run this script:"
    if [ "$OS" = "mac" ]; then
        echo "  brew install uv"
    else
        echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
    fi
    return 1
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

if check_uv && make_venv; then
    install_base_packages
    install_uv_tools
    echo
    echo "New interactive shells activate this automatically, unless a venv is"
    echo "already active - an explicitly chosen project venv is never replaced."
    echo
    echo "Add project packages with the venv active:"
    echo "  uv pip install -e <path-to-checkout>"
    echo
    echo "Reset it completely with:"
    echo "  rm -rf $VENVDIR && $ENVDIR/config_python.sh"
fi

echo "============== END: config_python.sh ==================="
