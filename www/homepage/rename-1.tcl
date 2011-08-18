# $Id: rename-1.tcl,v 3.0.4.1 2000/04/28 15:11:03 carsten Exp $
# File:     /homepage/rename-1.tcl
# Date:     Wed Jan 19 02:07:35 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to rename a file or folder

set_form_variables
# filesystem_node, rename_node

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

# ------------------------------ htmlGeneration codeBlock ----

set db [ns_db gethandle]
set filename [database_to_tcl_string $db "
select filename from users_files
where file_id=$rename_node"]

set pretty_name [database_to_tcl_string $db "
select file_pretty_name from users_files
where file_id=$rename_node"]

set dialog_body "Please choose a new name for `$filename' \
<form method=post action=rename-2.tcl> \
  <input type=hidden name=filesystem_node value=$filesystem_node> \
  <input type=hidden name=rename_node value=$rename_node> \
  <table cellpadding=0 border=0> \
    <tr> \
      <td align=left>new name: \
      <td><input type=text size=16 name=new_name value=\"$filename\"></tr> \
    <tr> \
      <td align=left>description: \
      <td><input type=text size=40 name=new_desc value=\"$pretty_name\"></tr> \
  </table> \
  <table border=0 cellpadding=0> \
  <tr><td><input type=submit value=Okay></form></td> \
      <td><form method=get action=index.tcl> \
          <input type=hidden name=filesystem_node value=$filesystem_node> \
          <input type=submit value=Cancel></form></td> \
  </tr></table>"


ad_returnredirect "dialog-class.tcl?title=Filesystem Management&text=$dialog_body"
return

ReturnHeaders

set title "Rename File/Folder"

ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "index.tcl?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>

<form method=post action=rename-2.tcl>
  <input type=hidden name=filesystem_node value=$filesystem_node>
  <input type=hidden name=rename_node value=$rename_node>
  <p><br>
  <ul> 
  <table cellpadding=4>
    <tr>
      <th align=left>new name for `$filename':
      <td><input type=text size=16 name=new_name></tr>
  </table>
  <input type=submit value=Rename>
  </ul>
</form>

</blockquote>
[ad_footer]
"
