# /homepage/rename-1.tcl

ad_page_contract {
    Allow to rename a file or a directory.

    @param filesystem_node The top directory the file will be renamed in.
    @param rename_node The file to rename.

    @creation-date Jan 14 18:48:26 EST 2000
    @author mobin@mit.edu
    @cvs-id rename-1.tcl,v 3.3.2.5 2000/09/22 01:38:18 kevin Exp

} {
    filesystem_node:notnull,naturalnum
    rename_node:notnull,naturalnum
}

# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------------ htmlGeneration codeBlock ----

set filename [db_string filename {
    select filename from users_files
    where file_id=:rename_node
}]

set pretty_name [db_string pretty_name {
    select file_pretty_name from users_files
    where file_id=:rename_node
}]

db_release_unused_handles

set dialog_body "Please choose a new name for `$filename' \
<form method=post action=rename-2> \
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
      <td><form method=get action=index> \
          <input type=hidden name=filesystem_node value=$filesystem_node> \
          <input type=submit value=Cancel></form></td> \
  </tr></table>"

ad_returnredirect "dialog-class?title=Filesystem Management&text=$dialog_body"
return

set title "Rename File/Folder"

set document "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "index?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>

<form method=post action=rename-2>
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

doc_return  200 text/html $document

