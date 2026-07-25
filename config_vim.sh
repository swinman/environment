#!/bin/sh
#
# config_vim.sh - vim packages, config links and plugins.
#
# Plugins load from vim 8's native package directory, ~/.vim/pack/plugins/
# start, instead of pathogen.  vim puts every directory found there on
# runtimepath by itself, which is all pathogen was doing.  An existing
# ~/.vim/bundle tree and autoload/pathogen.vim are moved into ~/.vim/unused
# rather than deleted.

ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)}
. "$ENVDIR/config_common.sh"

if [ "$OS" = "windows" ]; then
    VIMDIR=$HOME/vimfiles
    VIMRC=$HOME/_vimrc
else
    VIMDIR=$HOME/.vim
    VIMRC=$HOME/.vimrc
fi
PACKDIR=$VIMDIR/pack/plugins/start
UNUSED=$VIMDIR/unused
GH=https://github.com

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #

get_vim_packages() {
    if [ "$OS" = "linux" ]; then
        echo "Getting required vim packages"
        sudo apt-get install vim -y
        # vim-gtk3 is not about gvim: Ubuntu's plain vim package is built
        # -clipboard, and this is how terminal vim gets the "* and "+ registers
        sudo apt-get install vim-gtk3 -y
        sudo apt-get install vim-doc -y
        # universal-ctags replaces exuberant-ctags, which has been unmaintained
        # since 2009 and mis-parses enough modern C and python to send
        # jump-to-definition to the wrong place
        sudo apt-get install universal-ctags -y
        sudo apt-get install curl -y
        # not vim dependencies: pandoc and lynx are what the `md` alias uses to
        # read markdown in the terminal.  They live here because this is the
        # only script that installs packages on linux.
        sudo apt-get install pandoc -y
        sudo apt-get install lynx -y
    elif [ "$OS" = "mac" ]; then
        echo "Getting required vim packages"
        # brew vim rather than Apple's /usr/bin/vim, which is built -python3
        # -lua -perl -ruby.  config_mac.sh installs vim too; doing it here as
        # well is deliberate so this script stands alone, and brew install is a
        # no-op when the formula is already present.
        brew install vim
        brew install universal-ctags
    fi
}

check_vim_features() {
    echo "Checking vim build: $(command -v vim)"
    echo "  $(vim --version | head -1)"
    for feat in clipboard termguicolors python3; do
        if vim --version | grep -q -- "+$feat"; then
            echo "  +$feat"
        else
            echo "  -$feat"
        fi
    done
    if ! vim --version | grep -q -- '+python3'; then
        echo "  NOTE: -python3 means UltiSnips cannot run against this vim."
        echo "        snipMate is the pure-vimscript alternative if snippets"
        echo "        turn out to be missed."
    fi
    if ! vim --version | grep -q -- '+clipboard'; then
        echo "  WARNING: -clipboard, so \"* and \"+ will not reach the system"
        echo "           pasteboard."
    fi
}

config_vim_files() {
    echo "Linking vim config from $ENVDIR"

    # $VIMRC sources the repo copy rather than being a symlink to it, so
    # machine-local settings can be added after the source line.
    line="source $ENVDIR/_vimrc"
    [ -e "$VIMRC" ] || touch "$VIMRC"
    # -F: fixed string, so windows backslashes need no escaping dance
    if grep -qF "$line" "$VIMRC"; then
        echo "  $VIMRC already sources the repo _vimrc"
    else
        echo "$line" >> "$VIMRC"
        echo "  added \"$line\" to $VIMRC"
    fi

    mkdir -p "$VIMDIR/colors"
    for src in "$ENVDIR"/colorvim/colors/*.vim; do
        [ -e "$src" ] || continue
        _cv=$(basename "$src")
        link_config "colorvim/colors/$_cv" "$VIMDIR/colors/$_cv"
    done

    # Link the whole after tree rather than file by file: vim finds
    # after/syntax/<ft>.vim by searching runtimepath, and ~/.vim/after is a
    # runtimepath entry in its own right, sourced last so it can override the
    # stock runtime syntax files.  The source directory is after_vim and not
    # after so that tabbing "vim" still completes vim_config.sh.
    link_config after_vim "$VIMDIR/after"
}

config_vim_dirs() {
    # _vimrc keeps swap, backup and undo files here rather than next to the
    # source being edited.  vim's default 'directory' starts with ".", so
    # without this the swap files land in whatever repo is open.
    mkdir -p "$VIMDIR/backup" "$VIMDIR/swap" "$VIMDIR/undo"
    echo "Backup, swap and undo directories ready under $VIMDIR"
}

retire_pathogen() {
    if [ -e "$VIMDIR/autoload/pathogen.vim" ] || [ -d "$VIMDIR/bundle" ]; then
        echo "Retiring pathogen; plugins now load from pack/plugins/start"
        retire_path "$VIMDIR/bundle" "$UNUSED"
        retire_path "$VIMDIR/autoload/pathogen.vim" "$UNUSED"
    fi
}

get_vim_plugins() {
    echo "Getting vim plugins into $PACKDIR"
    mkdir -p "$PACKDIR"

    clone_or_pull "$GH/tpope/vim-fugitive.git"   "$PACKDIR/vim-fugitive"
    clone_or_pull "$GH/tpope/vim-surround.git"   "$PACKDIR/vim-surround"
    clone_or_pull "$GH/jiangmiao/auto-pairs.git" "$PACKDIR/auto-pairs"
    # scrooloose/nerdtree moved to preservim/nerdtree
    clone_or_pull "$GH/preservim/nerdtree.git"   "$PACKDIR/nerdtree"
    # G-code syntax, for reading .nc and .ngc files
    clone_or_pull "$GH/gregjurman/vim-nc.git"    "$PACKDIR/vim-nc"
    # ALE replaces syntastic, which linted synchronously and froze vim while
    # the checker ran
    clone_or_pull "$GH/dense-analysis/ale.git"   "$PACKDIR/ale"
    # Official git mirror of the mercurial repo at heptapod.host/cgtk/
    # taghighlight, so neither mercurial nor git-remote-hg is needed - and an
    # hg:: remote tangles git tab completion.  The mirror can lag upstream.
    clone_or_pull "$GH/abudden/taghighlight-automirror.git" \
        "$PACKDIR/taghighlight"

    # Dropped deliberately, and retired with ~/.vim/bundle above:
    #   pathogen      - vim 8 native packages do this
    #   syntastic     - replaced by ALE
    #   vim-sensible  - vim 8's own defaults cover it, and _vimrc sets these
    #                   options explicitly anyway
    #   ultisnips     - needs +python3; revisit if snippets are missed
    #   jedi-vim      - was already commented out
    #   neocomplcache - was already being moved to ~/.vim/unused
    #   swinman/taghighlight - the fork is behind upstream, nothing local in it

    # windows .inf driver files as dosini
    VIMFT=$VIMDIR/filetype.vim
    echo "if exists('did_load_filetypes')" > "$VIMFT"
    echo "    finish" >> "$VIMFT"
    echo "endif" >> "$VIMFT"
    echo "augroup filetypedetect" >> "$VIMFT"
    echo "autocmd BufNewFile,BufRead *.inf setf dosini" >> "$VIMFT"
    echo "augroup END" >> "$VIMFT"
}

# --------------------- SETUP SCRIPT --------------------- #

echo "==================== config_vim.sh  ===================="

get_vim_packages
check_vim_features
config_vim_files
config_vim_dirs
retire_pathogen
get_vim_plugins

echo "=============== END: config_vim.sh  ===================="
