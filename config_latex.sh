#!/bin/sh

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
config_latex() {
  if [ "$OS" = "linux" ]; then
    sudo apt-get install dvipng -y
    sudo apt-get install xpdf -y
    sudo apt-get install rubber -y    # compile latex to pdf
    sudo apt-get install latexmk -y   # similar to rubber
    sudo apt-get install texlive-latex-base -y
#    sudo apt-get install texlive-latex-extra -y
    sudo apt-get install texlive-latex-recommended -y
#    sudo apt-get install texlive-plain-extra -y
#    sudo apt-get install texlive-generic-extra -y
#    sudo apt-get install texlive-science -y
    if [ "$(lsb_release -r | sed "s/.*\s\+\(.*\)/\1/")" = "12.04" ]; then
      echo "Version is 12.04, installing texlive backport"
      sudo apt-add-repository http://ppa.launchpad.net/texlive-backports/ppa/ubuntu
      sudo apt-get update
      sudo apt-get install texlive-base -y
      sudo apt-get install texlive-xcolor -y
#      sudo apt-get install texlive-latex-extra -y
#      sudo apt-get install texlive-science -y
    fi
  fi
}

config_drawing() {
  if [ "$OS" = "linux" ]; then
    sudo apt-get install gimp -y
    sudo apt-get install inkscape -y
  elif [ $OS = windows ]; then
    echo "http://www.inkscape.org/en/download/"
    echo "http://www.gimp.org/downloads/"
  fi
}

get_fonts() {
  mkdir -p ~/.fonts
  config_adobe;
  get_adobe_open_fonts;
  if [ "$OS" = "linux" ]; then
    sudo apt-get install lcdf-typetools -y
    sudo apt-get install ttf-mscorefonts-installer -y
    sudo apt-get install ttf-oxygen-font-family -y
    sudo apt-get install texlive-fonts-recommended -y
#    sudo apt-get install texlive-fonts-extra -y
#    sudo apt-get install texlive-font-utils -y
  fi
}

config_adobe() {
  if [ "$OS" = "linux" ]; then
    CODENAME=$(lsb_release -a | grep Codename | sed 's/^Codename:\s*//')
    echo "codename is $CODENAME"
    sudo add-apt-repository "deb http://archive.canonical.com/ $CODENAME partner"
    sudo apt-get update
    sudo apt-get install acroread -y
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

  if [ "$OS" = "linux" ]; then
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
  fi
}

# for getting fonts:
# http://www.monperrus.net/martin/using-truetype-fonts-with-texlive-pdftex-pdflatex

# --------------------- RUN THE SCRIPT ------------------------------- #
echo "==================== config_latex.sh ==================="
config_latex;
config_drawing;
get_fonts;
echo "=============== END: config_latex.sh ==================="

# vim: shiftwidth=2
