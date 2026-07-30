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
        # No apt vim: Ubuntu 22.04's package is 8.2, and yegappan/lsp is
        # vim9script gated on v:version >= 900, so get_vim9 below builds vim
        # from source instead.  These are its build dependencies - libxt-dev
        # is what makes --with-x yield +clipboard in terminal vim, and
        # python3-dev provides the embedded python UltiSnips needs.
        sudo apt-get install build-essential -y
        sudo apt-get install libncurses-dev -y
        sudo apt-get install libxt-dev -y
        sudo apt-get install python3-dev -y
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

get_vim9() {
    # vim 9, from source, linux only.  Ubuntu 22.04's apt tops out at 8.2,
    # which cannot load yegappan/lsp, and the jonathonf PPA's 9.0.0749
    # predates patches the plugin checks for (up to 9.0.1629).  mac gets a
    # current vim from brew, so only linux takes this path.
    #
    # Installs into ~/.local, which interactive shells put ahead of /usr/bin
    # on PATH, so no sudo is needed and the apt vim is left alone.
    [ "$OS" = "linux" ] || return 0
    if vim --version 2>/dev/null | head -1 | grep -q 'IMproved 9'; then
        echo "vim 9 present: $(command -v vim)"
        return 0
    fi

    echo "Building vim 9 into $HOME/.local"
    _v9_src=${softwaredir:-$HOME/software}/vim
    clone_or_pull https://github.com/vim/vim.git "$_v9_src"
    # --with-python3-command pins the embedded interpreter to the system
    # python.  Left to configure, the first python3 on PATH wins - an active
    # venv, or a conda env - and the embedded python is bound at build time,
    # so vim quietly loses +python3 or breaks outright when that environment
    # is later removed.
    (cd "$_v9_src" &&
        ./configure --prefix="$HOME/.local" --with-features=huge \
            --enable-python3interp --with-python3-command=/usr/bin/python3 \
            --with-x &&
        make -j"$(nproc)" && make install) >/dev/null ||
        echo "  WARNING: vim build failed; run make in $_v9_src to see why"
}

get_vhdl_server() {
    # vhdl_ls, the VHDL language server registered in after_vim/plugin/lsp.vim.
    # Neither brew nor apt packages it, so this takes a release build.
    #
    # The install layout is the part to be careful with.  vhdl_ls finds its
    # bundled ieee and std libraries by looking beside the executable, and the
    # path it resolves is the one it was launched from, not a symlink's
    # target: linked onto PATH from an unpacked tree elsewhere, it panics at
    # startup.  ../share/vhdl_libraries is one of the directories it searches,
    # so the binary goes in ~/.local/bin and the libraries in ~/.local/share,
    # which is the layout that needs no arguments to find them.
    _vl_bin=$HOME/.local/bin
    _vl_share=$HOME/.local/share

    if command -v vhdl_ls >/dev/null 2>&1; then
        echo "vhdl_ls present: $(vhdl_ls --version)"
        return 0
    fi

    case "$OS" in
        mac)   _vl_asset=vhdl_ls-aarch64-apple-darwin ;;
        linux) _vl_asset=vhdl_ls-x86_64-unknown-linux-gnu ;;
        *)
            echo "  no vhdl_ls build for $OS; VHDL keeps tag highlighting"
            return 1
            ;;
    esac

    echo "Getting vhdl_ls ($_vl_asset)"
    _vl_url=$(curl -sL \
        https://api.github.com/repos/VHDL-LS/rust_hdl/releases/latest |
        grep -o "\"browser_download_url\": *\"[^\"]*$_vl_asset.zip\"" |
        cut -d'"' -f4)
    if [ -z "$_vl_url" ]; then
        echo "  WARNING: no $_vl_asset.zip in the latest release, skipping"
        return 1
    fi

    _vl_tmp=$(mktemp -d) || return 1
    if curl -sL -o "$_vl_tmp/vhdl_ls.zip" "$_vl_url" &&
            unzip -q "$_vl_tmp/vhdl_ls.zip" -d "$_vl_tmp"; then
        mkdir -p "$_vl_bin" "$_vl_share"
        rm -rf "$_vl_share/vhdl_libraries"
        mv "$_vl_tmp/$_vl_asset/vhdl_libraries" "$_vl_share/vhdl_libraries"
        mv "$_vl_tmp/$_vl_asset/bin/vhdl_ls" "$_vl_bin/vhdl_ls"
        chmod +x "$_vl_bin/vhdl_ls"
        echo "  installed $("$_vl_bin/vhdl_ls" --version) to $_vl_bin"
    else
        echo "  WARNING: could not fetch or unpack $_vl_url"
    fi
    rm -rf "$_vl_tmp"
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

retire_taghighlight() {
    # Left installed, it would keep reading any types_*.taghl still lying in a
    # source tree, and a syn keyword does not lose to a language server - it
    # colours every occurrence of a name whatever the server determined about
    # that one.  Machines that ran the old vim_config.sh have both.
    if [ -d "$PACKDIR/taghighlight" ]; then
        echo "Retiring taghighlight; the language servers highlight now"
        retire_path "$PACKDIR/taghighlight" "$UNUSED"
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
    #   taghighlight  - the language servers colour per scope, where this could
    #                   only match tag names globally across every buffer.  Its
    #                   last output still in use was types_py.taghl, and what
    #                   that covered was the names basedpyright could not
    #                   resolve, so it was masking a python import problem
    #                   rather than adding anything

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
get_vim9
get_vhdl_server
check_vim_features
config_vim_files
config_vim_dirs
retire_pathogen
retire_taghighlight
get_vim_plugins

echo "=============== END: config_vim.sh  ===================="
