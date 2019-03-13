#!/bin/sh

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_python3_packages() {
    echo "Getting required python packages"
    if [ "$OS" = "linux" ]; then
        # python 3 versions
        sudo apt-get install python3 -y

        # TODO check if ubuntu > specific version where pip not necessary
        sudo apt-get install python3-tk -y

        # needed to buil qrc
        sudo apt-get install libfreetype6-dev -y        # matplotlib
        sudo apt-get install libpng3 -y                 # matplotlib

        if [ -z "$( pip3 --version 2> /dev/null )" ]; then
            sudo apt-get install python3-pip -y
        fi
        sudo -H pip3 install --upgrade pip
        #sudo -H pip3 install --upgrade Cython
        sudo apt-get remove python3-pip -y
        sudo apt-get autoremove -y

        pip3 install --upgrade --user argcomplete
        pip3 install --upgrade --user cxfreeze
        pip3 install --upgrade --user ipython
        pip3 install --upgrade --user jsonpickle
        pip3 install --upgrade --user jupyter
        pip3 install --upgrade --user matplotlib
        pip3 install --upgrade --user numpy
        pip3 install --upgrade --user opencv-python
        pip3 install --upgrade --user pandas
        pip3 install --upgrade --user plotly
        pip3 install --upgrade --user psutil
        pip3 install --upgrade --user pyfirmata
        pip3 install --upgrade --user pyparsing
        pip3 install --upgrade --user pyqt5
        pip3 install --upgrade --user pyserial
        pip3 install --upgrade --user pyusb
        pip3 install --upgrade --user qtconsole
        pip3 install --upgrade --user scipy
        pip3 install --upgrade --user simplegeneric
        pip3 install --upgrade --user snakeviz
        pip3 install --upgrade --user svg.path
        pip3 install --upgrade --user sympy
        pip3 install --upgrade --user tables
        pip3 install --upgrade --user urllib3
        pip3 install --upgrade --user scikit-image
        pip3 install --upgrade --user scikit-umfpack


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
