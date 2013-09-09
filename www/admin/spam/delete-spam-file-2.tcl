# www/admin/spam/delete-spam-file-2.tcl

ad_page_contract {

Delete of a file from dropzone

    @param filename name of file to be deleted
    @author hqm@arsdigita.com
    @cvs-id delete-spam-file-2.tcl,v 3.4.2.3 2000/07/21 03:58:00 ron Exp
} {
    filename
}

set clean_filename [spam_sanitize_filename $filename]
set path [spam_file_location $clean_filename]

# copy the tmp file to the drop zone
if {[catch {ns_unlink $path} errmsg]} {
    ad_return_error "error deleting file"  "error deleting file using ns_unlink $path: $errmsg"
} else {
    ad_returnredirect "show-daily-spam.tcl"
}

