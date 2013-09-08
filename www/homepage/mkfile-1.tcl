# File:     /homepage/mkfile-1.tcl

ad_page_contract {
    Page to create an empty file

    @param filesystem_node System variable to get us back to the start

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Wed Jan 19 02:07:35 EST 2000
    @cvs-id mkfile-1.tcl,v 3.3.2.5 2000/09/22 01:38:17 kevin Exp
} {
    filesystem_node:notnull,naturalnum
}

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
<form method=post action=mkfile-2> \
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
      <td><form method=get action=index> \
          <input type=hidden name=filesystem_node value=$filesystem_node> \
          <input type=submit value=Cancel></form></td> \
  </tr></table>"

ad_returnredirect "dialog-class?title=Filesystem Management&text=$dialog_body"
return

set title "Create File"

set page_content "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "index?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>

<form method=post action=mkfile-2>
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

# Return the page for viewing
doc_return  200 text/html $page_content