#!/usr/bin/ipython3 -i
import os

def walkdrive( drive_top, backup_top ):

    drive_top = drive_top.rstrip('/\\')
    backup_top = backup_top.rstrip('/\\')

    if not os.path.exists( drive_top ):
        print( "Drive not found {}".format( drive_top ) )
        return

    if not os.path.exists( backup_top ):
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
            if st_base.st_size != st_backup.st_size:
                print( "SIZE ERR    : {}".format( path ) )
                print( "    original {:.2f}mb vs backup {:.2f}mb".format(
                    st_base.st_size * 1e-6, st_backup.st_size * 1e-6 ) )
            elif st_base.st_mtime > st_backup.st_mtime + 1:
                print( "MODIFY ERR  : {}".format( path ) )
                print( "    original modified {:.0f}s since backup".format(
                    st_base.st_mtime - st_backup.st_mtime ) )
        if False and not missing:
            print( "Found everything in {}".format( base ) )
            print( "                 in {}".format( base_backup ) )



if __name__ == "__main__":
    pass
