# $Id: upload-1.tcl,v 3.0.4.1 2000/04/28 15:11:04 carsten Exp $
# File:     /homepage/upload-1.tcl
# Date:     Tue Jan 18 22:58:22 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Upload File form

set_form_variables
# filesystem_node

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

set db [ns_db gethandle]

set next_node [database_to_tcl_string $db "
select users_file_id_seq.nextval from dual"]

ns_db releasehandle $db

set dialog_body "Please select a local file to upload: <form enctype=multipart/form-data method=post action=upload-2.tcl> <input type=hidden name=filesystem_node value=$filesystem_node> <input type=file name=upload_file size=20> <input type=hidden name=new_node value=$next_node><table border=0 cellpadding=0 cellspacing=0><tr><td> <input type=submit value=Okay></form></td>  <td><form method=get action=index.tcl><input type=hidden name=filesystem_node value=$filesystem_node><input type=submit value=Cancel></form></td></tr></table>"

set dialog_file "dialog-class.tcl?title=Filesystem Management&text=$dialog_body"

ad_returnredirect "$dialog_file"
return

ReturnHeaders 

set title "Upload File"

ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws [list "index.tcl?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>
"

append html "
<form enctype=multipart/form-data method=post action=upload-2.tcl>
[export_form_vars filesystem_node]

<table cellpadding=3>

<tr><th align=left>Upload File 
<td>
<input type=file name=upload_file size=20>
</tr>


</table>

<input type=hidden name=new_node value=$next_node>
<p>
<input type=submit value=\"Upload\">
</form>
<p>
"

ns_write "
<blockquote>
$html
</blockquote>
[ad_footer]
"






