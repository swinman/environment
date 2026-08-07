#!/bin/sh
# List attached USB devices.  mac has no lsusb of its own, and the two obvious
# substitutes are both dead ends here: `system_profiler SPUSBDataType` returns
# exit 0 with empty output on this machine, and brew's `lsusb` is a shell
# script wrapping that same command, so it is equally empty.
#
# ioreg reads the IOUSB registry plane directly and does work.  Only
# IOUSBHostDevice nodes are asked for, so hubs, controllers and the per-device
# interface children stay out of the listing.
#
# ioreg reports idVendor and idProduct in decimal, while they are quoted in hex
# everywhere else, so they are converted.  The serial number is printed because
# two of the same model are otherwise indistinguishable.

ioreg -p IOUSB -c IOUSBHostDevice -r -w0 -l 2>/dev/null | awk '
# Everything after the first "= " is the value; the key is quoted, so it can
# never contain the separator.
function val(s) {
    sub(/^[^=]*= /, "", s)
    gsub(/^"|"$/, "", s)
    return s
}
# Held until the next node starts, since the properties arrive in no fixed
# order and the widths are not known until every record is in.
function keep() {
    if (vid == "")
        return
    n++
    ident[n] = sprintf("%04x:%04x", vid + 0, pid + 0)
    prod[n] = product
    vend[n] = vendor
    serial[n] = ser
    if (length(product) > wp)
        wp = length(product)
    if (length(vendor) > wv)
        wv = length(vendor)
}
/\+-o /                 { keep(); vid = ""; pid = ""; product = ""; vendor = ""; ser = "" }
/"idVendor" =/          { vid = val($0) }
/"idProduct" =/         { pid = val($0) }
/"USB Product Name" =/  { product = val($0) }
/"USB Vendor Name" =/   { vendor = val($0) }
/"USB Serial Number" =/ { ser = val($0) }
END {
    keep()
    if (n == 0) {
        print "no USB devices attached"
        exit
    }
    for (i = 1; i <= n; i++)
        printf "%s  %-*s  %-*s  %s\n", ident[i], wp, prod[i], wv, vend[i], serial[i]
}
'
