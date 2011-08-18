# $Id: mkfile-1.tcl,v 3.0.4.1 2000/04/28 15:11:01 carsten Exp $
# File:     /homepage/mkfile-1.tcl
# Date:     Wed Jan 19 02:07:35 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to create an empty file

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

set dialog_body " \
<form method=post action=mkfile-2.tcl> \
  <input type=hidden name=filesystem_node value=$filesystem_node> \
  <table cellpadding=0 border=0> \
    <tr> \
      <td align=left> \
      Please choose a filename for the new file you wish to create. The filename you choose must end in .html (or .htm) if it's a HTML (webpage) file or it must end in .text (or .txt) if it's a plain text file. If your file does not have a .html, .htm, .text, or .txt extension then it will not be editable! \
      </tr> \
    <tr> \
      <td align=left>filename to create: \
      <td><input type=text size=16 name=new_name></tr> \
    <tr> \
      <td align=left>file description: \
      <td><input type=text size=40 name=new_desc></tr> \
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

set title "Create File"

ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "index.tcl?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>

<form method=post action=mkfile-2.tcl>
  <input type=hidden name=filesystem_node value=$filesystem_node>
  <p><br>
  <ul>
Please choose a filename for the new file you wish to create. The filename you choose must end in .html (or .htm) if it's a HTML (webpage) file, or it must end in .text (or .txt) if it's a plain text file. If your file does not have a .html, .htm, .text, or .txt extension then it will not be editable!<br>
  <table cellpadding=4>
    <tr>
      <th align=left>filename to create:
      <td><input type=text size=16 name=new_name></tr>
  </table>
  <input type=submit value=\"Create It!\">
  </ul>
</form>

</blockquote>
[ad_footer]
"



