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
        # clangd is what _vimrc points ALE at for c.  It reads a project's
        # compile_commands.json, so it lints with the real cross-compile
        # flags rather than the host compiler's.
        sudo apt-get install clangd -y
        # ALE lints sh with this.  There is a lot of shell in this repo alone,
        # and it catches the portability class of bug that took two `sed -i`
        # calls in vim_config.sh a long time to surface.
        #
        # Note the wording above: a comment whose first word is the tool's
        # own name is read as a directive, and an unparseable directive makes
        # it give up on the rest of the file.
        sudo apt-get install shellcheck -y
        # basedpyright is npm-packaged and not in apt.  It is only needed for
        # python semantic highlighting, so its absence costs highlighting
        # rather than anything else working.
        if ! command -v basedpyright-langserver >/dev/null 2>&1; then
            echo "  NOTE: no basedpyright - python semantic highlighting off."
            echo "  install with: npm install -g basedpyright"
        fi
        # pandoc and lynx were here only for the `md` markdown reader function,
        # which has been removed from _aliases, so neither is installed now.
    elif [ "$OS" = "mac" ]; then
        echo "Getting required vim packages"
        # brew vim rather than Apple's /usr/bin/vim, which is built -python3
        # -lua -perl -ruby.  config_mac.sh installs vim too; doing it here as
        # well is deliberate so this script stands alone, and brew install is a
        # no-op when the formula is already present.
        brew install vim
        brew install universal-ctags
        brew install shellcheck
        # basedpyright, for python semantic highlighting.  Deliberately brew
        # and not `uv tool install`: uv and pip here are pointed at a private
        # CodeArtifact index whose token expires, so a PyPI install fails with
        # a 401 whenever the login has lapsed.  A tool the editor needs should
        # not depend on that.
        brew install basedpyright
        # clangd, for ALE's c linting, ships with the Xcode command line
        # tools - /usr/bin/clangd, currently Apple clangd 15.  Deliberately
        # not `brew install llvm` for it: that is a 1.9GB keg-only install,
        # and the bundled one handles the arm-none-eabi cross builds here
        # given --query-driver, which _vimrc passes.
        if command -v clangd >/dev/null 2>&1; then
            echo "clangd present: $(clangd --version | head -1)"
        else
            echo "  WARNING: no clangd - ALE will not lint c."
            echo "  install the Xcode command line tools: xcode-select --install"
        fi
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
        echo "  WARNING: -python3, so the installed UltiSnips will not load."
        echo "           On mac this usually means Apple's /usr/bin/vim is"
        echo "           ahead of brew's on PATH; config_mac.sh's"
        echo "           config_brew_path fixes that.  snipMate is the"
        echo "           pure-vimscript alternative if it cannot be fixed."
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

    # The spell word list.  _vimrc compiles this to the .add.spl vim actually
    # reads, on the first launch that finds the list newer, so there is no
    # compile step here.  The .spl lands next to the link, in $VIMDIR, so no
    # build artifact appears in the repo.  The file name has to match
    # 'spelllang' and 'encoding'; _vimrc leaves both at the defaults.
    mkdir -p "$VIMDIR/spell"
    link_config _spellvim "$VIMDIR/spell/en.utf-8.add"
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
    # Needs +python3, which is why this was held back until brew's vim was
    # ahead of Apple's on PATH.  _vimrc already carries the UltiSnips block:
    # it appends $softwaredir/environment to runtimepath and sets
    # g:UltiSnipsSnippetDirectories to ["snippits","UltiSnips"], so the repo's
    # snippits/ is found by runtimepath search without any symlink.
    clone_or_pull "$GH/SirVer/ultisnips.git"     "$PACKDIR/ultisnips"
    # LSP client, pure vim9script - no node, unlike coc.nvim, and no need for
    # neovim.  Registered in after_vim/plugin/lsp.vim, because pack/*/start
    # loads after vimrc and g:LspAddServer does not exist until it has.
    #
    # This is here for semantic highlighting: the server says what each
    # identifier is in this file and this scope, where TagHighlight could only
    # match tag names globally across every buffer.
    clone_or_pull "$GH/yegappan/lsp.git"         "$PACKDIR/lsp"

    # Dropped deliberately, and retired with ~/.vim/bundle above:
    #   pathogen      - vim 8 native packages do this
    #   syntastic     - replaced by ALE
    #   vim-sensible  - vim 8's own defaults cover it, and _vimrc sets these
    #                   options explicitly anyway
    #   jedi-vim      - was already commented out
    #   neocomplcache - was already being moved to ~/.vim/unused
    #   swinman/taghighlight - the fork is behind upstream, nothing local in it

    # pathogen#helptags() rebuilt these on every vim startup.  vim does not do
    # it for packages, so generate them once here instead.  Each doc directory
    # is passed explicitly rather than using :helptags ALL, which would depend
    # on runtimepath being populated in a throwaway vim.
    echo "  generating plugin help tags"
    for doc in "$PACKDIR"/*/doc; do
        [ -d "$doc" ] || continue
        vim -es -u NONE -c "helptags $doc" -c 'q' >/dev/null 2>&1 ||
            echo "  WARNING: helptags failed for $doc"
    done

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
