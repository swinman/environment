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
        sudo apt-get install ipython3 -y
        sudo apt-get install python3-numpy -y
        sudo apt-get install python3-matplotlib -y
        sudo apt-get install python3-serial -y
        sudo apt-get install python3-pyqt4 -y
        sudo apt-get install python3-urllib3 -y
        # needed to buil qrc
        sudo apt-get install pyqt4-dev-tools -y
        sudo apt-get install cx-freeze -y
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
        # python 2 versions
        sudo apt-get install python2.7 -y
        sudo apt-get install ipython -y
        sudo apt-get install python-numpy -y
        sudo apt-get install python-matplotlib -y
        sudo apt-get install python-serial -y
        sudo apt-get install python-qt4 -y
        sudo apt-get install python-setuptools -y
        # python usb (pyusb)
        sudo apt-get install python-usb -y
        sudo apt-get install python-pip -y
        # sudo pip install --upgrade pyusb
        # needed to build qrc
        sudo apt-get install pyqt4-dev-tools -y
        # needed to build application
        sudo apt-get install cx-freeze -y
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

config_python() {
    echo "Add the software directory to python path"
    echo $softwaredir > 0addedpath.pth
    if [ "$OS" = "linux" ]; then
        sudo cp 0addedpath.pth /usr/local/lib/python2.7/dist-packages
        sudo mv 0addedpath.pth /usr/local/lib/python3.*/dist-packages
    elif [ "$OS" = "windows" ]; then
        cp 0addedpath.pth 'C:\Python27\Lib\site-packages'
        mv 0addedpath.pth 'C:\Python33\Lib\site-packages'
    elif [ "$OS" = "mac" ]; then
        mv 0addedpath.pth ~/Library/Python/2.7/lib/python/site-packages
    fi
}

# --------------------- SETUP SCRIPT --------------------- #
echo "=================== config_python.sh ==================="
get_python2_packages;
get_python3_packages;
config_python;
echo "============== END: config_python.sh ==================="
