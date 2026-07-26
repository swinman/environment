#!/bin/sh
#
# config_venv.sh - create the default python virtual environment.
#
# One venv, activated by every interactive shell (config_shell.sh writes the
# activation into its bracketed rc block).  The point is that `pip install`
# lands somewhere disposable instead of on a system python, and that the whole
# environment can be deleted and rebuilt with one command.
#
# Deliberately generic.  Nothing site-specific or employer-specific belongs in
# this file.  Installing project packages into the venv is a separate one-time
# step, not a shell-startup concern - see the closing message.
#
# uv supplies the interpreter, downloading one if no matching version is
# installed, so this does not depend on any particular system python.

ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)}
. "$ENVDIR/config_common.sh"

# Keep VENVDIR in sync with the activation that config_shell.sh writes.
VENVDIR=${VENVDIR:-$HOME/.venvs/dev}
VENVPY=${VENVPY:-3.12}

echo "==================== config_venv.sh ===================="

if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found.  Install it first: brew install uv"
    echo "=============== END: config_venv.sh ===================="
    exit 1
fi

if [ -f "$VENVDIR/bin/activate" ]; then
    echo "venv already present at $VENVDIR"
    echo "  $("$VENVDIR/bin/python" -V 2>&1)"
else
    echo "Creating venv at $VENVDIR (python $VENVPY)"
    # --seed installs pip and setuptools.  Plain `uv venv` creates an
    # environment with no pip at all, which defeats the purpose here.
    mkdir -p "$(dirname "$VENVDIR")"
    if uv venv --seed --python "$VENVPY" "$VENVDIR"; then
        echo "  created"
    else
        echo "  FAILED to create $VENVDIR"
        echo "=============== END: config_venv.sh ===================="
        exit 1
    fi
fi

echo
echo "New interactive shells activate this automatically, unless a venv is"
echo "already active - an explicitly chosen project venv is never replaced."
echo
echo "To put project packages in it:"
echo "  . $VENVDIR/bin/activate"
echo "  uv pip install -e <path-to-checkout>"
echo
echo "To reset it completely:"
echo "  rm -rf $VENVDIR && $ENVDIR/config_venv.sh"
echo "=============== END: config_venv.sh ===================="
