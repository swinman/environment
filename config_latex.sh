#!/bin/sh

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
config_latex() {
    if [ "$OS" = "linux" ]; then
        sudo apt-get install dvipng
        sudo apt-get install xpdf
        sudo apt-get install rubber         # compile latex to pdf
        sudo apt-get install latexmk        # similar to rubber
        sudo apt-get install texlive-latex-base
        sudo apt-get install texlive-latex-extra
        sudo apt-get install texlive-latex-recommended
        sudo apt-get install texlive-plain-extra
        sudo apt-get install texlive-generic-extra
        sudo apt-get install texlive-science
    fi
}

config_drawing() {
    if [ "$OS" = "linux" ]; then
        sudo apt-get install gimp
        sudo apt-get install inkscape
    fi
}

get_fonts() {
    mkdir -p ~/.fonts
    config_adobe;
    get_adobe_open_fonts;
    if [ "$OS" = "linux" ]; then
        sudo apt-get install lcdf-typetools
        sudo apt-get install ttf-mscorefonts-installer
        sudo apt-get install ttf-oxygen-font-family
        sudo apt-get install texlive-fonts-recommended
        sudo apt-get install texlive-fonts-extra
        sudo apt-get install texlive-font-utils
    fi
}

config_adobe() {
    if [ "$OS" = "linux" ]; then
        CODENAME=$(lsb_release -a | grep Codename | sed 's/^Codename:\s*//')
        echo "codename is $CODENAME"
        sudo add-apt-repository "deb http://archive.canonical.com/ $CODENAME partner"
        sudo apt-get update
        sudo apt-get install acroread
        if [ $? -eq 0 ]; then
            cp /opt/Adobe/Reader9/Resource/Font/*.otf ~/.fonts
        fi
    fi
}

get_adobe_open_fonts () {
    FONT_NAME="SourceCodePro"
    URL="http://sourceforge.net/projects/sourcecodepro.adobe/files/latest/download"
    FN2="SourceSansPro"
    URL2="http://sourceforge.net/projects/sourcesans.adobe/files/latest/download?source=files"

    mkdir -p /tmp/adodefont
    cd /tmp/adodefont
    NEW=false
    if [ $(ls ~/.fonts | grep $FONT_NAME | wc -l) -eq 0 ]; then
        wget ${URL} -O ${FONT_NAME}.zip
        unzip -o -j ${FONT_NAME}.zip
        mv *.otf ~/.fonts
        NEW=true
    fi
    if [ $(ls ~/.fonts | grep $FN2 | wc -l) -eq 0 ]; then
        wget ${URL2} -O ${FN2}.zip
        unzip -o -j ${FN2}.zip
        mv *.otf ~/.fonts
        NEW=true
    fi
    if [ $NEW = true ]; then
        fc-cache -f -v
    fi
}

# for getting fonts:
# http://www.monperrus.net/martin/using-truetype-fonts-with-texlive-pdftex-pdflatex

# --------------------- RUN THE SCRIPT ------------------------------- #
echo "==================== config_latex.sh ==================="
config_latex;
config_drawing;
get_fonts;
echo "========================================================"
