# File:     /homepage/mknh-1.tcl

ad_page_contract {
    Page to create a neighborhood

    @param neighborhood_node System variable to get us back to the start

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Thu Jan 27 01:06:47 EST 2000
    @cvs-id mknh-1.tcl,v 3.3.2.10 2000/09/22 01:38:17 kevin Exp
} {
    neighborhood_node:notnull,naturalnum
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

set ad_administrator_p [ad_administrator_p $user_id]


if { !$ad_administrator_p } {
    ad_return_error "Not allowed to create neighborhood" "You may not create a neighborhood unless you are a site-wide administrator."
    return
}

db_release_unused_handles

# ------------------------------ htmlGeneration codeBlock ----

set dialog_body "Please choose a name for the neighborhood. Also Choose a description for this neighborhood.<br><form method=post action=mknh-2> \
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
  <td><form method=get action=neighborhoods> \
  <input type=hidden name=neighborhood_node value=$neighborhood_node> \
  <input type=submit value=Cancel></form></td> \
  </tr> \
  </table>"

ad_returnredirect "dialog-class?title=Neighborhood Management&text=$dialog_body"
return

set title "Create Neighborhood"

set page_content "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index \
        [list "neighborhoods?neighborhood_node=$neighborhood_node" "Homepage Maintenance"] $title]
<hr>
<blockquote>

<form method=post action=mknh-2>
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

# Return the page for viewing
doc_return  200 text/html $page_content




