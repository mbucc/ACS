# File:     /homepage/renamenh-1.tcl

ad_page_contract {
    Page to rename a neighborhood

    @param neighborhood_node System variable to get us back to the start
    @param rename_node ID of what to rename

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Thu Jan 27 01:52:07 EST 2000
    @cvs-id renamenh-1.tcl,v 3.3.2.9 2000/09/22 01:38:18 kevin Exp
} {
    neighborhood_node:notnull,naturalnum
    rename_node:notnull,naturalnum
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


set neighborhood_name [db_string select_neighborhood_name "
select neighborhood_name from users_neighborhoods
where neighborhood_id=:rename_node"]

set pretty_name [db_string select_rename_pretty_name "
select description from users_neighborhoods
where neighborhood_id=:rename_node"]

db_release_unused_handles

set dialog_body "Please choose a new name for `$neighborhood_name' \
<form method=post action=renamenh-2> \
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
      <td><form method=get action=neighborhoods> \
          <input type=hidden name=neighborhood_node value=$neighborhood_node> \
          <input type=submit value=Cancel></form></td> \
  </tr></table>"

ad_returnredirect "dialog-class?title=Neighborhood Management&text=$dialog_body"
return

set title "Rename File/Folder"

set page_content "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "neighborhoods?neighborhood_node=$neighborhood_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>

<form method=post action=renamenh-2>
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

# Return page for viewing
doc_return  200 text/html $page_content