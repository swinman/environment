#!/usr/bin/python3
import os

def walkdrive( drive_top, backup_top ):

    drive_top = drive_top.rstrip('/\\')
    backup_top = backup_top.rstrip('/\\')

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
                print( "MISSING DIR : {}".format( path ) )
                #print( "    searched  {}".format( backup ) )
        if False and not missing:
            print( "Found everything in {}".format( base ) )
            print( "                 in {}".format( base_backup ) )



if __name__ == "__main__":
    pass
