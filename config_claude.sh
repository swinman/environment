#!/bin/sh
#
# config_claude.sh
# Installs Claude Code and points its global config at this repo, the same
# way _vimrc/_bash_aliases/_gitignore etc are symlinked into place elsewhere.
#
# NOTE ON WHAT GETS LINKED: ~/.claude/ also holds .credentials.json,
# .claude.json, session/project history, etc. Those are machine-specific
# and/or secrets - never symlink the whole directory into a git repo.
# Only settings.json and CLAUDE.md (the two files meant to be shared) get
# linked here.

# Adjust if these aren't already set by all_config.sh / config_bash.sh
: "${softwaredir:=$HOME/software}"
ENVREPO="${ENVREPO:-$softwaredir/environment}"

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #

get_claude_code() {
    if ! command -v claude >/dev/null 2>&1; then
        curl -fsSL https://claude.ai/install.sh | bash
        # installer usually appends its own PATH line, but confirm/add
        # ~/.local/bin just in case, same idempotent pattern as elsewhere
        if [ "$(grep -F '.local/bin' ~/.zshrc 2>/dev/null)" = "" ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
            echo "Added ~/.local/bin to PATH in ~/.zshrc"
        fi
    else
        echo "Claude Code already installed ($(claude --version))"
    fi
}

link_claude_config() {
    if [ ! -d "$ENVREPO" ]; then
        echo "ERROR: $ENVREPO not found - clone the environment repo first"
        return 1
    fi

    mkdir -p ~/.claude

    _link_one() {
        SRC="$ENVREPO/$1"
        DST="$HOME/.claude/$2"
        if [ ! -f "$SRC" ]; then
            echo "WARNING: $SRC missing in repo, skipping $2"
            return
        fi
        if [ -L "$DST" ]; then
            echo "$DST already symlinked"
            return
        fi
        if [ -e "$DST" ]; then
            mv "$DST" "$DST.bak.$(date +%Y%m%d%H%M%S)"
            echo "Backed up existing $DST"
        fi
        ln -s "$SRC" "$DST"
        echo "Linked $DST -> $SRC"
    }

    _link_one "_claude_settings.json" "settings.json"
    _link_one "_claude_CLAUDE.md" "CLAUDE.md"
}

# --------------------- SETUP SCRIPT --------------------- #

echo "===================== config_claude.sh ====================="

if [ "$OS" = "mac" ] || [ "$OS" = "linux" ]; then
    get_claude_code
    link_claude_config
fi

echo "=================== END: config_claude.sh ===================="
