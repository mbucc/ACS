# File:     /homepage/upload-1.tcl

ad_page_contract {
    Upload File form

    @param filesystem_node System variable to help get back where you started

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Tue Jan 18 22:58:22 EST 2000
    @cvs-id upload-1.tcl,v 3.3.2.8 2001/01/10 21:59:02 khy Exp
} {
    filesystem_node:notnull,naturalnum
}

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}


set new_node [db_string select_next_file_id "
select users_file_id_seq.nextval from dual"]

db_release_unused_handles

set dialog_body "Please select a local file to upload: <form enctype=multipart/form-data method=post action=upload-2> [export_form_vars -sign new_node]<input type=hidden name=filesystem_node value=$filesystem_node> <input type=file name=upload_file size=20><table border=0 cellpadding=0 cellspacing=0><tr><td> <input type=submit value=Okay></form></td>  <td><form method=get action=index><input type=hidden name=filesystem_node value=$filesystem_node><input type=submit value=Cancel></form></td></tr></table>"

set dialog_file "dialog-class?title=Filesystem Management&text=[ns_urlencode $dialog_body]"

ad_returnredirect "$dialog_file"
return

set title "Upload File"

set page_content "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws [list "index?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>

<blockquote>

<form enctype=multipart/form-data method=post action=upload-2>
[export_form_vars filesystem_node]
[export_form_vars -sign new_node]
<table cellpadding=3>

<tr><th align=left>Upload File 
<td>
<input type=file name=upload_file size=20>
</tr>

</table>


<p>
<input type=submit value=\"Upload\">
</form>
<p>
</blockquote>
[ad_footer]
"

# Return the page for viewing
doc_return  200 text/html $page_content

