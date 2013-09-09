# www/admin/spam/delete-spam-file.tcl

ad_page_contract {

 Confirm delete of a file from dropzone

    @param filename name of file to be deleted
    @author hqm@arsdigita.com
    @cvs-id delete-spam-file.tcl,v 3.3.6.4 2000/09/22 01:36:06 kevin Exp
} {
    filename
}

set clean_filename [spam_sanitize_filename $filename]
set path [spam_file_location $clean_filename]

append page_content "[ad_admin_header "Confirm Delete Spam File $clean_filename"]

[ad_admin_context_bar [list "index.tcl" "Spam"] "Delete Spam File"]

<hr>
<p>
Do you really want to delete spam file: <tt>$clean_filename</tt>?
<p>

<form action=delete-spam-file-2 method=post>
[export_form_vars filename]
<center><input type=submit value=\"Delete File\">
</center>
</form>

<p>
[ad_admin_footer]"

doc_return  200 text/html $page_content


