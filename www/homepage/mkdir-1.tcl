# $Id: mkdir-1.tcl,v 3.0.4.1 2000/04/28 15:11:01 carsten Exp $
# File:     /homepage/mkdir-1.tcl
# Date:     Fri Jan 14 18:48:26 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to create a folder

set_form_variables
# filesystem_node

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

set dialog_body "Please choose a name for the folder. Also Choose a description for this folder.<br><form method=post action=mkdir-2.tcl> \
  <input type=hidden name=filesystem_node value=$filesystem_node> \
  <table border=0 cellpadding=15> \
    <tr> \
      <th align=left>Folder name: \
      <td><input type=text size=16 name=dir_name></tr> \
    <tr> \
      <th align=left>Description: \
      <td><input type=text size=40 name=dir_desc></tr> \
  </table> \
  <table border=0 cellpadding=0> \
  <tr> \
  <td><input type=submit value=Okay></form></td> \
  <td><form method=get action=index.tcl> \
  <input type=hidden name=filesystem_node value=$filesystem_node> \
  <input type=submit value=Cancel></form></td> \
  </tr> \
  </table>"

ad_returnredirect "dialog-class.tcl?title=Filesystem Management&text=$dialog_body"
return

ReturnHeaders

set title "Create Folder"

ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "index.tcl?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>

<form method=post action=mkdir-2.tcl>
  [export_form_vars filesystem_node]
  <p><br>
  <ul>
  <table cellpadding=4>
    <tr>
      <th align=left>Folder Name:
      <td><input type=text size=16 name=dir_name></tr>
  </table>
  <input type=submit value=\"Make It!\">
  </ul>
</form>

</blockquote>
[ad_footer]
"