# $Id: delete-spam-file-2.tcl,v 3.2.2.1 2000/04/28 15:09:21 carsten Exp $
# delete-spam-file-2.tcl
#
# hqm@arsdigita.com
#
# confirmed delete of a file from dropzone

set_the_usual_form_variables
# form vars:
# filename

set clean_filename [spam_sanitize_filename $filename]
set path [spam_file_location $clean_filename]

# copy the tmp file to the drop zone
if {[catch {ns_unlink $path} errmsg]} {
    ReturnHeaders
    ns_write "error deleting file using ns_unlink $path: $errmsg"
} else {
    ad_returnredirect "show-daily-spam.tcl"
}


