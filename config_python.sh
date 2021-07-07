#!/bin/bash

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu




# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_python3_packages() {
    PY_PACKAGES="argcomplete cxfreeze ipython jsonpickle jupyter \
        numpy pandas psutil setuptools pyfirmata pyparsing \
        pyserial pyusb scipy pytimeparse simplegeneric \
        svg.path sympy tables urllib3 scikit-image scikit-umfpack sty"

    # only get these if we have a display
    if [ -n $DISPLAY ]; then
        PY_PACKAGES="$PY_PACKAGES plotly matplotlib opencv-python \
            qtconsole snakeviz"
    fi

    echo "Getting required python packages"
    if [ "$OS" = "linux" ]; then
        # python 3 versions
        sudo apt-get install python3 -y
        sudo apt-get install python3-dev -y
        sudo apt-get install python3-testresources -y

        # needed to buil qrc
        sudo apt-get install libfreetype6-dev -y        # matplotlib
        sudo apt-get install libpng3 -y                 # matplotlib

        if [ -n $DISPLAY ]; then
            sudo apt-get install python3-tk -y
        fi

        if [ -z "$( pip3 --version 2> /dev/null )" ]; then
            sudo apt-get install python3-pip -y
        fi
        sudo -H pip3 install --upgrade pip
        #sudo -H pip3 install --upgrade Cython
        sudo apt-get remove python3-pip -y
        sudo apt-get autoremove -y
        #sudo -H pip3 install mercurial

        # TODO check if ubuntu > specific version where pip not necessary

        for pkg in $PY_PACKAGES; do
            sudo -H pip3 install $pkg
        done

        if [ -n $DISPLAY ]; then
            sudo -H pip3 install pyqt5==5.9.2
        fi

        activate-global-python-argcomplete --user
    elif [ $OS = windows ]; then
        echo "It's probably easier to type 'gb' over each link from vim"
        echo "Install the 32 bit versions unless NumPy works for 64bit"
        echo "http://www.python.org/download/"
        echo "https://pypi.python.org/pypi/distribute"
        echo "https://pypi.python.org/pypi/pyreadline"
        echo "Ipython: Download and run as admin after installing distribute"
        echo "https://pypi.python.org/pypi/ipython#downloads"
        echo "http://www.sourceforge.net/projects/numpy/files/NumPy/"
        echo "http://www.matplotlib.org/downloads.html"
        echo "http://www.riverbankcomputing.com/software/pyqt/download/"
        echo "http://cx-freeze.sourceforge.net"
        echo "https://pypi.python.org/pypi/pyserial"
        echo ""
        echo "Installing Python Packages:"
        echo "(cd $softwaredir/environment && untar ~/Downloads/distribute-*)"
        echo "$ untar pyserial-2.*"
        echo "$ cd pyserial-2.*"
        echo "$ /c/Python33/python.exe setup.py install"
    fi
}

get_python2_packages() {
    echo "Getting required python packages"
    if [ "$OS" = "linux" ]; then
        sudo apt-get install python2.7 -y
    elif [ $OS = windows ]; then
        echo "It's probably easier to type 'gb' over each link from vim"
        echo "Install the 32 bit versions unless NumPy works for 64bit"
        echo "http://www.python.org/download/"
        echo "https://pypi.python.org/pypi/setuptools#downloads"
#        echo "https://pypi.python.org/pypi/distribute"
#        echo "https://pypi.python.org/pypi/pyreadline"
        echo "Ipython: don't worry about the start menu error"
        echo "https://pypi.python.org/pypi/ipython#downloads"
        echo "http://www.sourceforge.net/projects/numpy/files/NumPy/"
        echo "http://www.matplotlib.org/downloads.html"
        echo "http://www.riverbankcomputing.com/software/pyqt/download/"
        echo "http://cx-freeze.sourceforge.net"
        echo "https://pypi.python.org/pypi/pyserial"
        echo ""
        echo "Installing Python Packages:"
        echo "(cd $softwaredir/environment && untar ~/Downloads/distribute-*)"
        echo "$ untar pyserial-2.*"
        echo "$ cd pyserial-2.*"
        echo "$ /c/Python33/python.exe setup.py install"
    elif [ $OS = mac ]; then
        echo "Install python, pyqt, numpy, matplotlib - homebrew?"
        echo "install readline: sudo easy_install readline"
        echo "install ipython: download and unp, cd ipy, sudo setup.py install"
    fi
}

# --------------------- SETUP SCRIPT --------------------- #
echo "=================== config_python.sh ==================="
get_python2_packages;
get_python3_packages;
echo "============== END: config_python.sh ==================="
