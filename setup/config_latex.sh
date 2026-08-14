#!/bin/sh
#
# config_latex.sh - the LaTeX toolchain.
#
# The documents are NOT here.  The classes (lucidletter, lucidinvoice,
# lucidcheck), luciddocstyle.sty, bib.bib and the vendored font families live in
# the standalone latex repo, and that repo's own config.sh wires up its fonts.
# This script installs a distribution that can compile them, and makes the
# checkout findable by kpathsea.
#
# Dropped rather than ported, because both were dead where they stood:
#   - the Adobe Reader install, which existed only to copy the .otf files out of
#     /opt/Adobe/Reader9.  Reader for linux was discontinued in 2013, and those
#     font families are vendored in the latex repo now.
#   - the source-code-pro / source-sans-pro downloads, whose own code said
#     "FIXME: these fonts are broken -- must get archived otf release".  Also
#     vendored now.
# The Ubuntu 12.04 texlive-backports branch went with them.

SETUPDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$SETUPDIR/.." && pwd -P)}
. "$SETUPDIR/config_common.sh"
start_log "$@"

# Where the classes and styles live.  Overridable for a checkout elsewhere.
LATEXDIR=${LATEXDIR:-$HOME/software/latex}

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #

config_latex_mac() {
    # mactex-no-gui rather than mactex: the same complete TeX Live, minus
    # TeXShop, BibDesk, LaTeXiT and TeX Live Utility.  vim is the editor here
    # and the GUI apps would be four more things to keep updated.
    #
    # NOT basictex, which is the tempting 100MB option: luciddocstyle.sty pulls
    # floatflt, dutchcal and upgreek, and none of those ship in a minimal
    # install, so basictex means chasing tlmgr packages until the document
    # stops erroring.  latexmk comes with the full distribution, which is what
    # latexmk and rubber were both installed for on linux.
    #
    # It installs from a .pkg, so it needs sudo and cannot run unattended.
    brew install --cask mactex-no-gui

    # Skim rather than Preview: it does SyncTeX reverse search, so clicking a
    # line in the pdf jumps to that line in the source.  Preview only ever
    # displays the result.
    brew install --cask skim
}

config_latex_linux() {
    sudo apt-get install texlive-latex-base -y
    sudo apt-get install texlive-latex-extra -y
    sudo apt-get install texlive-latex-recommended -y
    sudo apt-get install texlive-fonts-recommended -y
    sudo apt-get install texlive-science -y
    sudo apt-get install texlive-plain-extra -y
    sudo apt-get install cm-super -y
    sudo apt-get install latexmk -y
    sudo apt-get install dvipng -y
    # texlive-font-utils for the type1 tooling the vendored otf families need
    # when a document does reach for one.
    sudo apt-get install texlive-font-utils -y
    sudo apt-get install lcdf-typetools -y
}

config_drawing() {
    # Figure and image tooling, kept here because these are what the documents
    # are illustrated with.
    if [ "$OS" = "mac" ]; then
        brew install --cask inkscape
        brew install --cask gimp
        brew install imagemagick
        brew install qpdf
        brew install pdftk-java
    elif [ "$OS" = "linux" ]; then
        sudo apt-get install inkscape -y
        sudo apt-get install gimp -y
        sudo apt-get install imagemagick -y
        sudo apt-get install qpdf -y
        sudo apt-get install pdftk-java -y
    fi
}

link_latex_tree() {
    # kpathsea searches TEXMFHOME recursively, and on mac TEXMFHOME is
    # ~/Library/texmf with nothing to configure.  The classes and styles sit
    # flat in the repo rather than in a TDS tree, so the whole checkout is
    # linked in once and the recursive search finds them.
    #
    # This is the mac counterpart of $LATEXDIR/config.sh's TEXMFLOCAL write,
    # which cannot work here: it edits /etc/texmf/texmf.d and runs
    # update-texmf, neither of which MacTeX has, and it needs sudo.  The user
    # tree needs neither.
    if [ ! -d "$LATEXDIR" ]; then
        echo "No latex checkout at $LATEXDIR - skipping the texmf link."
        echo "Clone it, then re-run this script (or set LATEXDIR)."
        return
    fi

    _texmf="$HOME/Library/texmf"
    mkdir -p "$_texmf/tex/latex" "$_texmf/bibtex/bib"

    # rm-then-link rather than `ln -shf`: -h is BSD ln's flag for "replace the
    # link instead of writing inside the directory it points at", GNU ln spells
    # the same thing -n, and GNU coreutils is ahead of BSD in PATH here.  The
    # explicit remove needs neither.
    for _dest in "$_texmf/tex/latex/lucid" "$_texmf/bibtex/bib/lucid"; do
        rm -f "$_dest"
        ln -s "$LATEXDIR" "$_dest"
        echo "Linked $_dest -> $LATEXDIR"
    done
}

verify_latex() {
    if ! command -v kpsewhich >/dev/null 2>&1; then
        echo "kpsewhich not on PATH yet."
        echo "MacTeX adds /Library/TeX/texbin through /etc/paths.d - open a new"
        echo "terminal, or run 'eval \$(/usr/libexec/path_helper -s)'."
        return
    fi
    echo "TEXMFHOME: $(kpsewhich -var-value TEXMFHOME)"
    for _f in luciddocstyle.sty lucidletter.cls bib.bib; do
        printf '  %-22s %s\n' "$_f" "$(kpsewhich "$_f" || echo 'NOT FOUND')"
    done
}

# --------------------- RUN THE SCRIPT ------------------------------- #

echo "==================== config_latex.sh ==================="

if [ "$OS" = "mac" ]; then
    config_latex_mac
elif [ "$OS" = "linux" ]; then
    config_latex_linux
else
    echo "Unknown OS '$OS' - install a TeX distribution by hand."
fi

config_drawing
link_latex_tree
verify_latex

echo "=============== END: config_latex.sh ==================="

# vim: shiftwidth=4
