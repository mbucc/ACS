# /homepage/mkdir-1.tcl

ad_page_contract {
    Display forms for creating a folder.

    @param filesystem_node The top directory displayed.

    @creation-date Fri Jan 14 18:48:26 EST 2000
    @author: Usman Y. Mobin (mobin@mit.edu)
    @cvs-id mkdir-1.tcl,v 3.2.6.3 2000/07/21 04:00:43 ron Exp
} {
    filesystem_node:notnull,naturalnum
}

# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------------ htmlGeneration codeBlock ----

set dialog_body "Please choose a name for the folder. Also Choose a description for this folder.<br><form method=post action=mkdir-2> \
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
  <td><form method=get action=index> \
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

<form method=post action=mkdir-2>
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