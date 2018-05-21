#!/usr/bin/python3
"""
Logging configuration
---------------------------------------
Use for configuring the log

modified 2018-05-19 21:49:19
"""

import os
import sys
#from importlib.util import find_spec
import logging
from logging import handlers

from drift import __version__

log = logging.getLogger(__name__)

LOG_INIT_STRING = " ===== Log Created ===== "
_LOG_CONFIGURED = False

ROOTLOGGER = None   # configured during config_log
BUFHANDLER = None   # configured during config_log
BUF_SIZE = 128      # number of records to store


def config_log(console_level=logging.DEBUG,
        console_disp_thread=False, console_disp_level=True,
        console_disp_line=True, console_disp_file=True,
        redirect_std=False, mem_handler=False,
        log_suppress_exceptions=False, debug_to_file=False,
        global_log_info_prog_name=None):
    """ configure the log
        kwargs include:
            console_level ( logging.DEBUG ) : level for console debug ( if not redirect_std )
            console_disp_thread ( False ) : display thread info on console
            console_disp_level ( False ) : set false to suppress level display in console
            console_disp_line ( True ) : set false to suppress line display in console
            console_disp_file ( False ) : set false to suppress file display in console
            redirect_std (False) : redirect stdin / stdout / stderr to log
            log_suppress_exceptions (False) : log attempts to suppress exceptions
            debug_to_file (False) : also write debug log to a file
            mem_handler (False) : add a logging handler to store records in memory
            global_log_info_prog_name (None) : name for writing log to ~/.logfiles
    """
    global _LOG_CONFIGURED
    if _LOG_CONFIGURED:
        log.debug( "Log has already been configured." )
    _LOG_CONFIGURED = True

    """ FORMAT SPECIFIERS
        asctime     %(asctime)s     Human-readable time when the LogRecord was created. By default this is of the form ‘2003-07-08 16:49:45,896’ (the numbers after the comma are millisecond portion of the time).
        created     %(created)f     Time when the LogRecord was created (as returned by time.time()).
        relativeCreated %(relativeCreated)d Time in milliseconds when the LogRecord was created, relative to the time the logging module was loaded.
        msecs       %(msecs)d       Millisecond portion of the time when the LogRecord was created.
        filename    %(filename)s    Filename portion of pathname.
        funcName    %(funcName)s    Name of function containing the logging call.
        levelname   %(levelname)s   Text logging level for the message ('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL').
        levelno     %(levelno)s     Numeric logging level for the message (DEBUG, INFO, WARNING, ERROR, CRITICAL).
        lineno      %(lineno)d      Node line number where the logging call was issued (if available).
        module      %(module)s      Module (name portion of filename).
        message     %(message)s     The logged message, computed as msg % args. This is set when Formatter.format() is invoked.
        name        %(name)s        Name of the logger used to log the call.
        pathname    %(pathname)s    Full pathname of the source file where the logging call was issued (if available).
        process     %(process)d     Process ID (if available).
        processName %(processName)s Process name (if available).
        thread      %(thread)d      Thread ID (if available).
        threadName  %(threadName)s  Thread name (if available).
    """
    file_fmt = [ "%(levelname)-7s", "%(threadName)-12s", "%(lineno)4d",
            "%(name)-16s", "%(asctime)s", "%(message)s" ]
    console_fmt = [ "%(message)s" ]
    disp_fmt = [ "%(asctime)s", "%(message)s" ]

    logging.captureWarnings(True)     # integrate warnings with logging
    logging.raiseExceptions = not log_suppress_exceptions

    if console_disp_file:
        console_fmt.insert(0, "%(name)-16s")
    if console_disp_line:
        console_fmt.insert(0, "%(lineno)4d")
    if console_disp_thread:
        console_fmt.insert(0, "%(threadName)-10s")
    if console_disp_level:
        console_fmt.insert(0, "%(levelname)-7s")

    log_fmt_file = logging.Formatter( " ".join( file_fmt ),
            datefmt="%m-%d %H:%M:%S" )
    log_fmt_console = logging.Formatter(" ".join(console_fmt[:-1])+'|'+console_fmt[-1])
    log_fmt_disp = logging.Formatter( " | ".join(disp_fmt),
            datefmt="%m-%d %H:%M:%S" )

    rootLogger = logging.getLogger()
    rootLogger.setLevel( logging.DEBUG )

    if debug_to_file:
        debugfile = logging.FileHandler( "DEBUG.log", mode='w' )
        debugfile.setLevel( logging.DEBUG )
        debugfile.setFormatter( log_fmt_file )
        rootLogger.addHandler( debugfile )

    if redirect_std:
        sys.stdin = _StdRedirect( "stdin" )
        sys.stdout = _StdRedirect( "stdout" )
        sys.stderr = _StdRedirect( "stderr", level=logging.ERROR )
        sys.__stdin__ = _StdRedirect( "_stdin_" )
        sys.__stdout__ = _StdRedirect( "_stdout_" )
        sys.__stderr__ = _StdRedirect( "_stderr_", level=logging.ERROR )
    else:
        console = logging.StreamHandler( sys.stderr )
        console.setFormatter( log_fmt_console )
        console.setLevel( console_level )
        rootLogger.addHandler( console )

    if mem_handler:
        global BUFHANDLER
        BUFHANDLER = BufferHandler()
        BUFHANDLER.setLevel(logging.INFO)
        BUFHANDLER.setFormatter(log_fmt_disp)
        rootLogger.addHandler(BUFHANDLER)

    if global_log_info_prog_name is not None:
        global_log_dir = os.path.expanduser(os.path.join('~', ".logfiles" ))
        if not os.path.exists( global_log_dir ):
            os.makedirs(global_log_dir)
        global_log_name = os.path.join(global_log_dir, global_log_info_prog_name + ".log")

        """
        use an auto-managed 'rolling' file handler with 3x 2MB files, such that
        total file size will always be between 4MB and 6MB (just after and
        before roll-over respectively)
        """
        infofile = handlers.RotatingFileHandler(global_log_name, maxBytes=2e6, backupCount=2)
        infofile.setLevel(logging.INFO)
        infofile.setFormatter(log_fmt_file)
        rootLogger.addHandler(infofile)

    global ROOTLOGGER
    ROOTLOGGER = rootLogger

    log.info(LOG_INIT_STRING)


class BufferHandler( handlers.BufferingHandler ):
    def __init__( self ):
        super().__init__(BUF_SIZE)
        self._emit_cb = None

    def registerCB( self, callback ):
        """ callback fcn the signature cb( str, levelno ) """
        self._emit_cb = callback

    def removeCB( self ):
        self._emit_cb = None

    def flush( self ):
        self.acquire()
        try:
            if self._emit_cb is not None:
                for record in self.buffer:
                    self._emit_cb( self.format( record ),
                            getattr( record, "levelno" ) )
            self.buffer = []
        finally:
            self.release()

    def shouldFlush( self, record ):
        if self._emit_cb is not None:
            return True
        return super().shouldFlush( record )


class _StdRedirect( object ):
    """ Allows redirection of stdout / stderr / stdin to log
        when run on windows after cx_freezing, sys.stdout will be None
        which causes issues with ipython
    """
    def __init__( self, name, level=logging.INFO ):
        logger = logging.getLogger( name )
        if level == logging.DEBUG:
            self.logger = logger.debug
        elif level == logging.INFO:
            self.logger = logger.info
        elif level == logging.WARNING:
            self.logger = logger.warning
        elif level == logging.ERROR:
            self.logger = logger.error
        else:
            raise ValueError( "Invalid redirect log level" )

    def read( self, *args, **kwargs ): pass
    def flush( self ): pass
    def close( self, *args, **kwargs ): pass
    def write( self, txt ):
        lines = [ l.strip('\r') for l in txt.strip('\r\n').split( '\n' ) ]
        for l in txt.strip('\r\n').split('\n'):
            l.strip('\r')
            self.logger( l )


def get_versions( strfmt='{} {}', joiner=' - ' ):
    """ get all version info and format according to spec """
    from platform import python_version
    from PyQt5.QtCore import QT_VERSION_STR
    from PyQt5.QtCore import PYQT_VERSION_STR
    from numpy.version import full_version as np_ver
    import matplotlib as mpl
    mpl_ver = mpl.__version__
    from jsonpickle import VERSION as json_ver
    from IPython import version_info
    ipy_ver = '.'.join( str(i) for i in version_info if i != '' )
    from qtconsole import version_info
    qtc_ver = '.'.join( str(i) for i in version_info if i != '' )
    from usb import version_info
    usb_ver = '.'.join( str(i) for i in version_info if i != '' )

    vstrings = []
    vstrings.append( strfmt.format( "Python", python_version() ) )
    vstrings.append( strfmt.format( "Qt", QT_VERSION_STR ) )
    vstrings.append( strfmt.format( 'PyQt', PYQT_VERSION_STR ) )
    vstrings.append( strfmt.format( 'numpy', np_ver ) )
    vstrings.append( strfmt.format( 'matplotlib', mpl_ver ) )
    vstrings.append( strfmt.format( "jsonpickle", json_ver ) )
    vstrings.append( strfmt.format( "IPython", ipy_ver ) )
    vstrings.append( strfmt.format( "qtconsole", qtc_ver ) )
    vstrings.append( strfmt.format( "pyusb", usb_ver ) )
    return joiner.join( vstrings )


if __name__ == "__main__":
    import argparse    # TODO: use argparse instead of direct here

    def _make_parser():
        parser = argparse.ArgumentParser(description="Log configuration",
                add_help=False)
        parser.add_argument('-v', '--version', action='store_true',
                help='Get python version information')
        parser.add_argument('-h', '--help', action='store_true',
                help='Get log config args')
        parser.add_argument('-c', '--configure', action='store_true',
                help='Configure log and exit (useless)')
        return parser

    parser = _make_parser()
    args = parser.parse_args()
    if not len(sys.argv[1:]):
        print("Use -v or --version for python version info", file=sys.stderr)
        print("Use -h or --hep for log_config args", file=sys.stderr)
        print("Use -c or --configure to call log_config and exit", file=sys.stderr)
        #parser.print_help()     # or print_usage for less verbose

    if args.version:
        print(get_versions('{:20}: {}', '\n'))

    if args.help:
        print("FIXME: print log_config kwargs")

    if args.configure:
        config_log(console_level=logging.DEBUG)
