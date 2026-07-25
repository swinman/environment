#!/bin/sh
#
# config_mac.sh
# macOS environment setup - mirrors the pattern of config_avr_arm.sh / config_bash.sh
# Meant to be sourced/called from all_config.sh when $OS = "mac"
#
# Some steps below are one-time manual/GUI steps that can't be scripted
# (Gatekeeper prompts, System Settings panes, interactive key generation).
# These are printed as instructions rather than automated, same convention
# as the Windows/manual-download blocks in config_avr_arm.sh.

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #

check_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install it with:"
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        read -p "[ ENTER ] once Homebrew is installed." brew_dwn
    else
        echo "Homebrew already present"
    fi
}

get_core_packages() {
    brew install git
    brew install vim
    brew install coreutils
    brew install gnu-sed
    brew install grep
    brew install zsh-completions
    brew install pyenv
    brew install pipx
    brew install uv
    brew install awscli
    # what the `md` alias pipes through to read markdown in the terminal
    brew install pandoc
    brew install lynx
}

get_embedded_tools() {
    brew install arm-none-eabi-gcc
    brew install openocd
    brew install --cask segger-jlink
}

get_terminal() {
    brew install --cask iterm2
    echo
    echo "In iTerm2: Preferences > Profiles > Keys > set Option key as Esc+"
    echo "(gives you Alt/Meta bindings for vim/readline like on Linux)"
}

config_brew_path() {
    # /etc/paths.d/homebrew puts /opt/homebrew/bin on PATH, but macOS's
    # path_helper appends paths.d entries *after* /etc/paths, so it lands
    # behind /usr/bin.  Everything brew installs is then shadowed by Apple's
    # copy: `vim` resolves to Apple's 9.1 (-python3) rather than brew's 9.2
    # (+python3), and `git` to /usr/bin/git rather than the brew one.
    #
    # brew shellenv prepends instead.  It goes in ~/.zprofile because that is
    # read after /etc/zprofile has already run path_helper, so this wins.
    ZPROFILE=~/.zprofile
    BREWLINE='eval "$('$(command -v brew || echo /opt/homebrew/bin/brew)' shellenv)"'
    if [ "$(grep -F 'brew shellenv' $ZPROFILE 2>/dev/null)" = "" ]; then
        echo "$BREWLINE" >> $ZPROFILE
        echo "Added brew shellenv to $ZPROFILE (puts brew ahead of /usr/bin)"
    else
        echo "brew shellenv already present in $ZPROFILE"
    fi
}

config_gnu_tools_path() {
    # BSD userland ships by default on macOS (sed/grep/date/etc behave
    # differently than the GNU tools Ubuntu uses). Put GNU versions first
    # in PATH so scripts written against GNU flags keep working.
    ZSHRC=~/.zshrc
    GNULINE='export PATH="$(brew --prefix coreutils)/libexec/gnubin:$(brew --prefix gnu-sed)/libexec/gnubin:$(brew --prefix grep)/libexec/gnubin:$PATH"'
    if [ "$(grep -F "$GNULINE" $ZSHRC 2>/dev/null)" = "" ]; then
        echo "# GNU coreutils/sed/grep ahead of BSD versions in PATH" >> $ZSHRC
        echo "$GNULINE" >> $ZSHRC
        echo "Added GNU tools PATH override to $ZSHRC"
    else
        echo "GNU tools PATH override already present in $ZSHRC"
    fi
}

config_zsh_completion() {
    ZSHRC=~/.zshrc
    if [ "$(grep -F "compinit" $ZSHRC 2>/dev/null)" = "" ]; then
        echo "autoload -Uz compinit && compinit" >> $ZSHRC
        echo "Added compinit to $ZSHRC"
    else
        echo "compinit already present in $ZSHRC"
    fi
}

config_pyenv() {
    ZSHRC=~/.zshrc
    if [ "$(grep -F "pyenv init" $ZSHRC 2>/dev/null)" = "" ]; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $ZSHRC
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $ZSHRC
        echo 'eval "$(pyenv init -)"' >> $ZSHRC
        echo "Added pyenv init to $ZSHRC"
    else
        echo "pyenv init already present in $ZSHRC"
    fi
    echo
    echo "Reload your shell, then install a python version, e.g.:"
    echo "  pyenv install 3.12.6 && pyenv global 3.12.6"
    echo "Never pip install into /usr/bin/python3 (Apple's system python)."
    echo "Use venvs per project, or pipx for global CLI tools."
}

config_directories() {
    mkdir -p ~/software
    mkdir -p ~/tools
    echo "Created ~/software (projects) and ~/tools (downloaded toolchains)"
    echo
    echo "MANUAL STEP: exclude these from Spotlight indexing to avoid"
    echo "CPU/battery churn on build directories:"
    echo "  System Settings > Siri & Spotlight > Spotlight Privacy > add ~/software and ~/tools"
    echo
    echo "If Desktop/Documents iCloud sync is ever enabled, keep these dirs"
    echo "OUTSIDE ~/Desktop and ~/Documents so iCloud doesn't try to sync build artifacts."
}

config_ssh() {
    echo
    echo "MANUAL STEP: generate SSH keys for GitHub/Bitbucket (interactive, not scripted):"
    echo "  ssh-keygen -t ed25519 -C \"your_email@example.com\""
    echo
    echo "Then add to ~/.ssh/config so Keychain remembers your passphrase across reboots:"
    echo "  Host *"
    echo "    AddKeysToAgent yes"
    echo "    UseKeychain yes"
    echo "    IdentityFile ~/.ssh/id_ed25519"
    echo
    echo "  ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
    echo
    echo "Copy the public key to clipboard with pbcopy (macOS's xclip equivalent):"
    echo "  pbcopy < ~/.ssh/id_ed25519.pub"
    echo "Then add it under GitHub > Settings > SSH keys, and Bitbucket > Personal settings > SSH keys."
}

# the vim build check moved to config_vim.sh's check_vim_features, which also
# reports +python3 and +termguicolors rather than only +clipboard

# --------------------- SETUP SCRIPT --------------------- #

echo "======================== config_mac.sh ========================"

if [ "$OS" = "mac" ]; then
    check_homebrew
    config_brew_path
    get_core_packages
    get_terminal
    get_embedded_tools
    config_gnu_tools_path
    config_zsh_completion
    config_pyenv
    config_directories
    config_ssh
fi

echo "======================= END: config_mac.sh ====================="
