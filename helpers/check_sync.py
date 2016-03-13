#!/usr/bin/python3
import os

def walkdrive( drive_top, backup_top, check_timestamp=True, check_size=True ):
    drive_top = drive_top.rstrip('/\\')
    backup_top = backup_top.rstrip('/\\')

    if not os.path.isdir( drive_top ):
        print( "Drive not found {}".format( drive_top ) )
        return

    if not os.path.isdir( backup_top ):
        print( "Backup not found {}".format( backup_top ) )
        return

    def backup_path( drive_path ):
        return drive_path.replace( drive_top, backup_top )

    for base, folders, files in os.walk( drive_top ):
        base_backup = backup_path( base )
        if not os.path.exists( base_backup ):
            #print( "Skipping contents of {}".format( base_backup ) )
            continue
        missing = 0
        for f in folders:
            path = os.path.join( base, f )
            backup = backup_path( path )
            if not os.path.exists( backup ):
                missing += 1
                print( "MISSING DIR : {}".format( path ) )
                #print( "    searched  {}".format( backup ) )
        for f in files:
            path = os.path.join( base, f )
            backup = backup_path( path )
            if not os.path.exists( backup ):
                missing += 1
                print( "MISSING FILE: {}".format( path ) )
                #print( "    searched  {}".format( backup ) )
                continue
            st_base = os.stat( path )
            st_backup = os.stat( backup )
            if check_size and st_base.st_size != st_backup.st_size:
                print( "SIZE ERR    : {}".format( path ) )
                print( "    original {:.2f}mb vs backup {:.2f}mb".format(
                    st_base.st_size * 1e-6, st_backup.st_size * 1e-6 ) )
            elif check_timestamp and st_base.st_mtime > st_backup.st_mtime + 1:
                print( "MODIFY ERR  : {}".format( path ) )
                print( "    original modified {:.0f}s since backup".format(
                    st_base.st_mtime - st_backup.st_mtime ) )
        if False and not missing:
            print( "Found everything in {}".format( base ) )
            print( "                 in {}".format( base_backup ) )



if __name__ == "__main__":
    import sys
    err = False
    kwargs = dict()
    if len( sys.argv ) < 3:
        err = True

    _, drive, backup, *args = sys.argv
    if not os.path.isdir( drive ):
        print( "invalid drive: {}".format( drive ) )
        err = True
    elif not os.path.isdir( backup ):
        print( "invalid backup: {}".format( backup ) )
        err = True

    if '-t' in args:
        args.remove( '-t' )
        print( "ignoring timestamp" )
        kwargs["check_timestamp"] = False
    if '-s' in args:
        args.remove( '-s' )
        print( "ignoring size differences" )
        kwargs["check_size"] = False
    if '-r' in args:
        print( "reversing sync direction" )
        __tmp = drive
        drive = backup
        backup = __tmp

    if err:
        print( "./check_sync <drive_to_backup> <backup_location>" )
    else:
        print( "Checking that {} is backed up on {}".format( drive, backup ) )
        walkdrive( drive, backup, **kwargs )
        print( "DONE" )
