# /shared/1pixel.tcl

ad_page_contract {
    Generates a 1-pixel GIF image with a certain color.

    @author Jon Salz <jsalz@mit.edu>
    @date 28 Nov 1999
    @cvs-id 1pixel.tcl,v 3.2.8.3 2000/07/25 09:25:22 kevin Exp
    @param file
} {
    r:naturalnum,notnull
    g:naturalnum,notnull
    b:naturalnum,notnull
}

ReturnHeaders "image/gif"
#ReturnHeaders "text/html"

set file [open "[ns_info pageroot]/graphics/1pixel.header"]
ns_writefp $file
close $file

if { [util_aolserver_2_p] } {
    if { $r == 0 } { set r 1 }
    if { $g == 0 } { set g 1 }
    if { $b == 0 } { set b 1 }

    ns_write "[format "%c%c%c" $r $g $b]"
} else {
    # Can't figure out how to write binary data using AOLserver 3 (it
    # insist on UTF8-encoding it). So we write to a file, then dump
    # the file's contents.

    set file_name [ns_tmpnam]
    ns_log "Notice" "logging to $file_name"
    set file [open $file_name w+]
    fconfigure $file -encoding binary
    puts -nonewline $file "[format "%c%c%c" $r $g $b]"
    seek $file 0
    ns_writefp $file
    close $file
    ns_unlink $file_name
}

set file [open "[ns_info pageroot]/graphics/1pixel.footer"]
ns_writefp $file
close $file
