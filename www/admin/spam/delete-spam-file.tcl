# $Id: delete-spam-file.tcl,v 3.2 2000/03/08 07:39:58 hqm Exp $
# delete-spam-file.tcl
#
# hqm@arsdigita.com
#
# confirm delete of a file from dropzone

set_the_usual_form_variables
# form vars:
# filename

ReturnHeaders

set clean_filename [spam_sanitize_filename $filename]
set path [spam_file_location $clean_filename]

append pagebody "[ad_admin_header "Confirm Delete Spam File $clean_filename"]

[ad_admin_context_bar [list "index.tcl" "Spam"] "Delete Spam File"]

<hr>
<p>
Do you really want to delete spam file: <tt>$clean_filename</tt>?
<p>

<form action=delete-spam-file-2.tcl method=post>
[export_form_vars filename]
<center><input type=submit value=\"Delete File\">
</center>
</form>

<p>
[ad_admin_footer]"

ns_write $pagebody

