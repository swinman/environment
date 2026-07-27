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
    #brew install zsh-completions
    brew install uv
    brew install tmux
    # awscli is deliberately NOT a brew formula here - see get_aws_cli below.
    # Deliberately not installed:
    #   pyenv, pipx  - uv and uvx cover both jobs, and a second python manager
    #                  with no job is how pyenv ended up inert here: its global
    #                  was "system", its init was never added to ~/.zshrc, and
    #                  the 3.12.6 it built was unreachable.
    #   pandoc, lynx - only the `md` function used them, and that is removed.
}

get_aws_cli() {
    # NOT `brew install awscli`.  That formula runs on brew's python@3.14,
    # whose pyexpat links against the system /usr/lib/libexpat.1.dylib
    # instead of a bundled copy.  A bottle built on a newer macOS than the
    # one it is poured onto references expat symbols the local dylib does
    # not export, and every XML-parsing path then dies at import with a
    # dlopen "Symbol not found" error.  On 26.2 the missing symbol was
    # XML_SetAllocTrackerActivationThreshold, added in expat 2.7.2.
    #
    # This fails in a way that looks healthy: `aws --version` still prints
    # fine, because nothing has parsed XML yet.  It only surfaces on a real
    # API call or on `aws configure sso`.
    #
    # Amazon's own pkg is self-contained - it ships its own python and expat
    # under /usr/local/aws-cli - so brew python churn cannot reach it.  Note
    # that config_brew_path puts /opt/homebrew/bin ahead of /usr/local/bin,
    # so a stray `brew install awscli` would shadow this one.
    #
    # It installs from a .pkg, so it needs sudo and will prompt for a
    # password - it cannot run unattended.
    if command -v aws >/dev/null 2>&1; then
        echo "aws already present: $(aws --version 2>&1)"
        return
    fi
    _awsdir=$(mktemp -d)
    curl -fsSL -o "$_awsdir/AWSCLIV2.pkg" "https://awscli.amazonaws.com/AWSCLIV2.pkg"
    sudo installer -pkg "$_awsdir/AWSCLIV2.pkg" -target /
    rm -rf "$_awsdir"
}

get_embedded_tools() {
    # NOT `brew install arm-none-eabi-gcc`.  That formula is a bare cross
    # compiler with no C library: there is no arm-none-eabi/ sysroot in its
    # Cellar at all, and brew core has no newlib formula to add alongside it.
    # GCC's own stdint.h is a shim that does `#include_next <stdint.h>`
    # expecting newlib's, so every build dies with the baffling
    # "stdint.h: No such file or directory" pointing at stdint.h itself.
    #
    # The cask is ARM's official prebuilt toolchain and bundles newlib plus a
    # matched binutils and gdb.  Do not also install arm-none-eabi-binutils:
    # gcc invokes `as` and `ld` by name off PATH, so an unmatched binutils in
    # front of the cask's is a source of obscure link failures.
    #
    # It installs from a .pkg, so it needs sudo and will prompt for a
    # password - it cannot run unattended.
    brew install --cask gcc-arm-embedded
    # brew aliases `openocd` to the open-ocd formula
    brew install openocd
    brew install --cask segger-jlink
    # for identifying attached USB devices; mac has no lsusb of its own
    brew install lsusb
}

get_terminal() {
    brew install --cask iterm2
    echo
    echo "In iTerm2: Preferences > Profiles > Keys > set Option key as Esc+"
    echo "(gives you Alt/Meta bindings for vim/readline like on Linux)"
}

config_terminal_app() {
    # Terminal.app leaves the window open after `exit`, so every finished shell
    # leaves a dead "[Process completed]" window behind.
    #
    # This stays a manual step rather than a `defaults write`: the setting is
    # per-profile and lives in a nested dict inside com.apple.Terminal's
    # plist, whose values are serialised NSColor/NSFont blobs, so writing one
    # key means rewriting the whole profile and risking the rest of it.
    echo
    echo "MANUAL STEP: make \`exit\` close the window:"
    echo "  Terminal > Settings > Profiles > (your profile) > Shell >"
    echo "  When the shell exits: Close if the shell exited cleanly"
    echo
    echo "\"...if the shell exited cleanly\" rather than \"Close the window\", so"
    echo "a shell that died on a non-zero status leaves its output up to read."
    echo
    # Terminal.app auto-marks each prompt line, and cmd-L is "Clear to
    # Previous Mark".  With the two-line prompt that mark sits on the prompt
    # character line, so cmd-L clears the context line above it and leaves a
    # bare %.  ctrl-l is the one that clears properly - _completion_zsh
    # rebinds it to scroll into the scrollback buffer first, the way the linux
    # terminals do.
    echo "NOTE: cmd-L is Terminal's own \"Clear to Previous Mark\" and will eat"
    echo "the prompt's context line.  Use ctrl-l, or rebind cmd-L under"
    echo "Terminal > Settings > Profiles > Keyboard."
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
    #
    # The line goes at the TOP of the file, never appended to the end.  The
    # python.org installer writes its own prepend into ~/.zprofile, so
    # appending brew after it would put /opt/homebrew/bin ahead and silently
    # move python3 from the framework 3.12 to brew's 3.14 - which conflicts
    # with the 3.12 the manufacturing environment pins.  Prepending lets every
    # existing line prepend after brew, so brew wins for vim and git while
    # python3 stays wherever it already was.
    ZPROFILE=~/.zprofile
    BREWLINE='eval "$('$(command -v brew || echo /opt/homebrew/bin/brew)' shellenv)"'
    if [ "$(grep -F 'brew shellenv' $ZPROFILE 2>/dev/null)" != "" ]; then
        echo "brew shellenv already present in $ZPROFILE"
        return 0
    fi
    if [ -f $ZPROFILE ]; then
        cp $ZPROFILE $ZPROFILE.bak.$(date +%Y%m%d%H%M%S)
        echo "  backed up $ZPROFILE"
    fi
    # not sed -i: BSD sed reads -i's argument as a backup suffix, and there is
    # no portable in-place insert.  write-temp-then-replace matches
    # config_shell.sh, and `cat tmp > $ZPROFILE` rewrites in place so the
    # permissions survive.
    {
        echo "# brew ahead of /usr/bin (path_helper puts paths.d entries last)."
        echo "# Keep this above any later PATH prepend, e.g. python.org's."
        echo "$BREWLINE"
        echo ""
        if [ -f $ZPROFILE ]; then cat $ZPROFILE; fi
    } > $ZPROFILE.tmp \
        && cat $ZPROFILE.tmp > $ZPROFILE \
        && rm -f $ZPROFILE.tmp
    echo "Added brew shellenv at the top of $ZPROFILE"
}

config_gnu_tools_path() {
    # BSD userland ships by default on macOS (sed/grep/date/etc behave
    # differently than the GNU tools Ubuntu uses). Put GNU versions first
    # in PATH so scripts written against GNU flags keep working.
    #
    # Guarded on the gnubin directories actually existing.  `brew --prefix
    # grep` prints /opt/homebrew/opt/grep whether or not grep is installed, so
    # the unguarded version wrote a PATH line naming three directories that did
    # not exist, announced success, and left sed as BSD.  That silent failure is
    # why `sed -i "s/^$var\s.*//"` in vim_config.sh and `sed 's/\s.*//"` in
    # firmware makefiles kept misbehaving: BSD sed has no \s class and matches a
    # literal "s" instead.
    #
    # $HOMEBREW_PREFIX is exported by the brew shellenv line that
    # config_brew_path puts in ~/.zprofile, which is read before ~/.zshrc.
    # Using it rather than three `brew --prefix` calls saves about 19ms each at
    # every single shell start.
    BREWPFX=${HOMEBREW_PREFIX:-$(brew --prefix)}
    for _gnu in coreutils gnu-sed grep; do
        if [ ! -d "$BREWPFX/opt/$_gnu/libexec/gnubin" ]; then
            echo "GNU tools PATH override SKIPPED: $_gnu is not installed"
            echo "  run get_core_packages first, or: brew install $_gnu"
            return 1
        fi
    done
    ZSHRC=~/.zshrc
    GNULINE='export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$HOMEBREW_PREFIX/opt/grep/libexec/gnubin:$PATH"'
    # match on the shared substring, so a line written by the older
    # $(brew --prefix) form is recognised as already present rather than
    # duplicated alongside the new one
    if [ "$(grep -F 'libexec/gnubin' $ZSHRC 2>/dev/null)" = "" ]; then
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

config_remote_login() {
    # Incoming ssh, i.e. sshd.  This is the "Remote Login" checkbox in System
    # Settings > General > Sharing, and it is off by default on macOS.
    #
    # Optional and prompted, because enabling a listening service on a laptop
    # is not something to turn on silently.  Checked first so re-running is a
    # no-op on a machine where it is already enabled.
    #
    # systemsetup needs root, and on recent macOS the calling terminal also
    # needs Full Disk Access, otherwise it fails with an unhelpful error.
    if [ "$(sudo -n systemsetup -getremotelogin 2>/dev/null)" = "Remote Login: On" ]; then
        echo "Remote Login already enabled"
        return 0
    fi
    printf "Enable Remote Login (incoming ssh)? [y/N] "
    read _rl
    if [ "$_rl" = "y" ] || [ "$_rl" = "Y" ]; then
        sudo systemsetup -setremotelogin on
        sudo systemsetup -getremotelogin
    else
        echo "Skipped.  Enable later with:"
        echo "  sudo systemsetup -setremotelogin on"
        echo "or System Settings > General > Sharing > Remote Login"
    fi
}

# the vim build check moved to config_vim.sh's check_vim_features, which also
# reports +python3 and +termguicolors rather than only +clipboard

# --------------------- SETUP SCRIPT --------------------- #

echo "======================== config_mac.sh ========================"

if [ "$OS" = "mac" ]; then
    check_homebrew
    config_brew_path
    get_core_packages
    get_aws_cli
    # iTerm2 is not wanted by default.  The function is kept because it also
    # carries the Option-as-Meta setup note, which is worth having if it is
    # ever installed on a machine that does want it.
    #get_terminal
    get_embedded_tools
    config_gnu_tools_path
    config_zsh_completion
    config_terminal_app
    # pyenv is no longer installed by get_core_packages, so there is nothing
    # for its init to hook.  Function kept in case pyenv comes back.
    #config_pyenv
    config_directories
    config_ssh
    config_remote_login
fi

echo "======================= END: config_mac.sh ====================="
