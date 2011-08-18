# $Id: renamenh-1.tcl,v 3.0.4.1 2000/04/28 15:11:03 carsten Exp $
# File:     /homepage/renamenh-1.tcl
# Date:     Thu Jan 27 01:52:07 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to rename a neighborhood

set_form_variables
# neighborhood_node, rename_node

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
set neighborhood_name [database_to_tcl_string $db "
select neighborhood_name from users_neighborhoods
where neighborhood_id=$rename_node"]

set pretty_name [database_to_tcl_string $db "
select description from users_neighborhoods
where neighborhood_id=$rename_node"]

set dialog_body "Please choose a new name for `$neighborhood_name' \
<form method=post action=renamenh-2.tcl> \
  <input type=hidden name=neighborhood_node value=$neighborhood_node> \
  <input type=hidden name=rename_node value=$rename_node> \
  <table cellpadding=0 border=0> \
    <tr> \
      <td align=left>new name: \
      <td><input type=text size=16 name=new_name value=\"$neighborhood_name\"></tr> \
    <tr> \
      <td align=left>description: \
      <td><input type=text size=40 name=new_desc value=\"$pretty_name\"></tr> \
  </table> \
  <table border=0 cellpadding=0> \
  <tr><td><input type=submit value=Okay></form></td> \
      <td><form method=get action=neighborhoods.tcl> \
          <input type=hidden name=neighborhood_node value=$neighborhood_node> \
          <input type=submit value=Cancel></form></td> \
  </tr></table>"


ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=$dialog_body"
return

ReturnHeaders

set title "Rename File/Folder"

ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "neighborhoods.tcl?neighborhood_node=$neighborhood_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>

<form method=post action=renamenh-2.tcl>
  <input type=hidden name=neighborhood_node value=$neighborhood_node>
  <input type=hidden name=rename_node value=$rename_node>
  <p><br>
  <ul> 
  <table cellpadding=4>
    <tr>
      <th align=left>new name for `$neighborhood_name':
      <td><input type=text size=16 name=new_name></tr>
  </table>
  <input type=submit value=Rename>
  </ul>
</form>

</blockquote>
[ad_footer]
"
