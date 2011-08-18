# $Id: mknh-1.tcl,v 3.0.4.1 2000/04/28 15:11:02 carsten Exp $
# File:     /homepage/mknh-1.tcl
# Date:     Thu Jan 27 01:06:47 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to create a neighborhood

set_form_variables
# neighborhood_node

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

set dialog_body "Please choose a name for the neighborhood. Also Choose a description for this neighborhood.<br><form method=post action=mknh-2.tcl> \
  <input type=hidden name=neighborhood_node value=$neighborhood_node> \
  <table border=0 cellpadding=15> \
    <tr> \
      <th align=left>Neighborhood name: \
      <td><input type=text size=16 name=nh_name></tr> \
    <tr> \
      <th align=left>Description: \
      <td><input type=text size=66 name=nh_desc></tr> \
  </table> \
  <table border=0 cellpadding=0> \
  <tr> \
  <td><input type=submit value=Okay></form></td> \
  <td><form method=get action=neighborhoods.tcl> \
  <input type=hidden name=neighborhood_node value=$neighborhood_node> \
  <input type=submit value=Cancel></form></td> \
  </tr> \
  </table>"

ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=$dialog_body"
return

ReturnHeaders

set title "Create Neighborhood"

ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "neighborhoods.tcl?neighborhood_node=$neighborhood_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>

<form method=post action=mknh-2.tcl>
  [export_form_vars neighborhood_node]
  <p><br>
  <ul>
  <table cellpadding=4>
    <tr>
      <th align=left>Neighborhood Name:
      <td><input type=text size=16 name=nh_name></tr>
  </table>
  <input type=submit value=\"Make It!\">
  </ul>
</form>

</blockquote>
[ad_footer]
"