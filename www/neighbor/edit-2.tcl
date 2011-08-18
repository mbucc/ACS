# $Id: edit-2.tcl,v 3.0 2000/02/06 03:49:45 ron Exp $
set_form_variables

# neighbor_to_neighbor_id

set db [neighbor_db_gethandle]

set selection [ns_db 0or1row $db "select neighbor_to_neighbor.*, users.email as poster_email, users.first_names || ' ' || users.last_name as poster_name
from neighbor_to_neighbor, users
where neighbor_to_neighbor_id = $neighbor_to_neighbor_id
and neighbor_to_neighbor.poster_user_id = users.user_id"]
if { $selection == "" } {
    ns_return 200 text/html [neighbor_error_page 1 "<li>Could not find a posting with an id of $neighbor_to_neighbor_id"]
    return
}

# found the row
set_variables_after_query

ReturnHeaders

ns_write "[neighbor_header "$about : $one_line"]

<h2>$about : $one_line</h2>

posted by $poster_email ($poster_name) on $posted

<hr>

<h3>Story</h3>

$full_description_text
<form action=edit-3.tcl method=post>
<center>
[export_form_vars neighbor_to_neighbor_id]
<input type=submit name=edit_or_delete value=\"Edit\">
<input type=submit name=edit_or_delete value=\"Delete\">
</center>
</form>

[neighbor_footer]
"
