#!/bin/sh
#
# config_git.sh - global git configuration.
#
# Configuration only.  Two jobs that used to live here were removed rather
# than ported, because the platform scripts already own them and disagreed
# with the half-ported versions in here:
#
#   installing git    - config_mac.sh's get_core_packages does it via brew,
#                       and apt-get does it in the linux branch below.
#   generating a key  - config_mac.sh's config_ssh covers ed25519 plus the
#                       Keychain lines in ~/.ssh/config.  The version here
#                       still made an rsa key and pbcopy'd an id_rsa.pub it
#                       had not created.

ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)}
. "$ENVDIR/config_common.sh"

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

    if [ -z "$(git config --global user.name 2>/dev/null)" ] ||
       [ -z "$(git config --global user.email 2>/dev/null)" ]; then
        echo "  WARNING: user.name or user.email is still unset - commits will fail"
    fi
    if [ "$OS" = "mac" ]; then
        echo
        echo "ssh keys are not set up here - see config_ssh in config_mac.sh"
    fi
}


# --------------------- SETUP SCRIPT --------------------- #
echo "==================== config_git.sh  ===================="
get_git_packages;
config_git;
echo "================ END: config_git.sh ===================="
