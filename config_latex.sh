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
    sudo apt-get install texlive-latex-extra -y
    sudo apt-get install texlive-latex-recommended -y
    sudo apt-get install texlive-science -y
    sudo apt-get install texlive-plain-extra -y
    sudo apt-get install texlive-generic-extra -y
    if [ "$(lsb_release -r | sed "s/.*\s\+\(.*\)/\1/")" = "12.04" ]; then
      echo "Version is 12.04, installing texlive backport"
      sudo apt-add-repository http://ppa.launchpad.net/texlive-backports/ppa/ubuntu
      sudo apt-get update
      sudo apt-get install texlive-base -y
      sudo apt-get install texlive-xcolor -y
      sudo apt-get install texlive-latex-extra -y
      sudo apt-get install texlive-science -y
    fi
  fi
}

config_drawing() {
  if [ "$OS" = "linux" ]; then
    sudo apt-get install gimp -y
    sudo apt-get install ufraw -y
    sudo apt-get install inkscape -y
    sudo apt-get install imagemagick -y
    sudo apt-get install pdftk -y
  elif [ $OS = windows ]; then
    echo "http://www.inkscape.org/en/download/"
    echo "http://www.gimp.org/downloads/"
  fi
}

get_fonts() {
  mkdir ~/.fonts
  sudo apt-get install fontconfig -y
  config_adobe;
  get_adobe_open_fonts;
  if [ "$OS" = "linux" ]; then
    sudo apt-get install lcdf-typetools -y
    sudo apt-get install ttf-mscorefonts-installer -y
    sudo apt-get install ttf-dejavu -y
    sudo apt-get install ttf-oxygen-font-family -y
    sudo apt-get install texlive-fonts-recommended -y
    #sudo apt-get install texlive-fonts-extra -y    # 670 MB
    sudo apt-get install texlive-font-utils -y
  fi
  sudo fc-cache -fv
}

config_adobe() {
  sudo apt-get install libxm12:i386 -y

  if [ "$OS" = "linux" ]; then
    #CODENAME=$(lsb_release -a | grep Codename | sed 's/^Codename:\s*//')
    #echo "codename is $CODENAME"
    #sudo add-apt-repository "deb http://archive.canonical.com/ $CODENAME partner"
    sudo add-apt-repository "deb http://archive.canonical.com/ precise partner"
    sudo apt-get update
    #sudo apt-get install acroread -y
    sudo apt-get install adobereader-enu
    if [ $? -eq 0 ]; then
      cp /opt/Adobe/Reader9/Resource/Font/*.otf ~/.fonts
      #sudo cp /opt/Adobe/Reader9/Resource/Font/*.otf /usr/local/share/fonts
    fi
  fi
}

get_adobe_open_fonts () {
  FONT_NAME="source-code-pro"
  URLa="https://github.com/adobe-fonts/source-code-pro/releases/download/variable-fonts/SourceCodeVariable-Roman.otf"
  URLb="https://github.com/adobe-fonts/source-code-pro/releases/download/variable-fonts/SourceCodeVariable-Italic.otf"
  FN2="source-sans-pro"
  URL2a="https://github.com/adobe-fonts/source-sans-pro/releases/download/variable-fonts/SourceSansVariable-Roman.otf"
  URL2b="https://github.com/adobe-fonts/source-sans-pro/releases/download/variable-fonts/SourceSansVariable-Italic.otf"
  echo "FIXME: these fonts are broken -- must get archived otf release"
  if [ "$OS" = "linux" ]; then
      wget ${URLa}
      wget ${URLb}
      wget ${URL2a}
      wget ${URL2b}
      mv *.otf ~/.fonts
      #sudo mv *.otf /usr/local/share/fonts
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
