#!/bin/sh
#
# config_git.sh - global git configuration.
#
# Installing git is not done here: config_mac.sh's get_core_packages does it
# via brew, and apt-get does it in the linux branch below.
#
# Key setup is config_common.sh's config_ssh, called at the end.  It runs after
# config_git so it can label the key with the address just configured, and it
# has to run before all_config.sh reaches the private clone that follows.

SETUPDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$SETUPDIR/.." && pwd -P)}
. "$SETUPDIR/config_common.sh"

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_git_packages() {
    if [ "$OS" = "linux" ]; then
        echo "Getting required git packages"
        sudo apt-get install git -y
        sudo apt-get install xclip -y
        # mercurial and felipec/git-remote-hg used to be installed here.  The
        # only thing that ever needed them was cloning the taghighlight plugin
        # from heptapod; that plugin is retired (the language servers colour
        # identifiers now), so nothing in here speaks hg any more.  An hg::
        # remote also tangles git tab completion, a second reason not to
        # reintroduce one.
    elif [ "$OS" = "windows" ]; then
        echo "Download git and install using 'simple context menu' with bash"
        echo "Download from http://git-scm.com/download/win"
        echo "Install with the following options:"
        echo "run git from the windows command prompt -> add git to path"
        echo "checkout windows style, commit unix style"
    elif [ "$OS" = "mac" ]; then
        # Nothing to fetch.  brew's git is installed by config_mac.sh, and its
        # shellenv line puts /opt/homebrew/bin ahead of Apple's /usr/bin/git.
        #
        # This branch used to download git-completion.bash into ~/, which was
        # for mac-on-bash.  zsh gets git completion from brew's zsh-completions
        # and compinit, and config_shell.sh stopped sourcing that file, so the
        # download only left an orphan nothing read.
        echo "git comes from config_mac.sh (brew), nothing to fetch"
    fi
}

config_git() {
    echo
    echo "git version $(git --version | sed 's/^git version //'), configuring:"
    echo "   color ui to true"
    git config --global color.ui true
    # Fixed 256-color values instead of the ANSI names.  The names (red,
    # green, even brightred) are resolved through the terminal's palette,
    # and the dark profiles in use on both linux and mac map them to shades
    # that are hard to read on a near-black background.  Numeric values
    # bypass the palette and render the same everywhere; both GNOME
    # Terminal and Terminal.app support the 256-color set (Terminal.app
    # does not support 24-bit hex, so that form is avoided).
    echo "   diff colors to lighter 256-color values"
    git config --global color.diff.old "210"        # light red
    git config --global color.diff.new "120"        # light green
    git config --global color.diff.frag "117"       # light blue @@ hunks
    git config --global color.diff.func "117"       # function in @@ line
    git config --global color.diff.commit "222"     # light yellow
    git config --global color.diff.meta "252 bold"  # file header lines
    # The interactive colors (add -p and friends) are left at ANSI defaults
    # by git: bold blue for the prompt, bold red for both help and errors.
    # Those are the two shades the dark profiles render nearly invisible, so
    # they get 256-color values as well.  The picks stay clear of the diff
    # palette above - the prompt sits directly against the 117 hunk header,
    # and an error that matched 210 would read as a removed line.
    echo "   interactive colors to lighter 256-color values"
    git config --global color.interactive.prompt "213"  # light magenta
    git config --global color.interactive.error "226"   # bright yellow
    git config --global color.interactive.help "250"    # grey, recedes
    # push.default simple is unconditional now.  The value has existed since
    # git 1.7.11 and has been the default since 2.0, so the version gate that
    # used to guard it could not fire on anything still in use.  Its check was
    # broken anyway: the sed glued major and minor together, so 2.55.0 became
    # "255" and was compared against 19 as one number.
    echo "   push default to simple"
    git config --global push.default simple
    echo "   linking core excludes file"
    git config --global core.excludesfile "$ENVDIR/_gitignore"
    if [ "$OS" = "mac" ]; then
        # Only for https remotes.  ssh remotes authenticate with the key and
        # never consult a credential helper, so this is inert until a repo is
        # cloned over https - at which point it stores the token in the login
        # keychain instead of prompting on every fetch.
        echo "   credential helper to osxkeychain"
        git config --global credential.helper osxkeychain
    fi

    # ask_once rather than a bare read, so a run driven by all_config.sh uses
    # the answers taken at the start instead of stopping here for them.  An
    # empty answer still means "no change", including when it was given up
    # front and arrives as an exported but empty variable.
    ask_once CFG_GIT_USERNAME "Full user name (default is no change): "
    if [ -n "$CFG_GIT_USERNAME" ]; then
        echo "Setting git user.name to $CFG_GIT_USERNAME"
        git config --global user.name "$CFG_GIT_USERNAME"
    fi
    ask_once CFG_GIT_EMAIL "Email address (default is no change): "
    if [ -n "$CFG_GIT_EMAIL" ]; then
        echo "Setting git user.email to $CFG_GIT_EMAIL"
        git config --global user.email "$CFG_GIT_EMAIL"
    fi
    ask_once CFG_GIT_INITIAL_BRANCH "Default initial branch (default is no change): "
    if [ -n "$CFG_GIT_INITIAL_BRANCH" ]; then
        echo "Setting git default branch to $CFG_GIT_INITIAL_BRANCH"
        git config --global init.defaultBranch "$CFG_GIT_INITIAL_BRANCH"
    fi

    if [ -z "$(git config --global user.name 2>/dev/null)" ] ||
       [ -z "$(git config --global user.email 2>/dev/null)" ]; then
        echo "  WARNING: user.name or user.email is still unset - commits will fail"
    fi
}


# --------------------- SETUP SCRIPT --------------------- #
echo "==================== config_git.sh  ===================="
get_git_packages;
config_git;
if [ "$OS" = "linux" ] || [ "$OS" = "mac" ]; then
    config_ssh;
fi
echo "================ END: config_git.sh ===================="
