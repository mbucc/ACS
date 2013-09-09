# /www/neighbor/edit-2.tcl

ad_page_contract {
    Allows the user to edit one of the neighbor-to-neighbor entries.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id edit-2.tcl,v 3.1.6.3 2000/09/22 01:38:54 kevin Exp
    @param neighbor_to_neighbor_id the entry to edit or delete
} {
    neighbor_to_neighbor_id:integer,notnull
}

set db [neighbor_db_gethandle]

set sql_query "
  select neighbor_to_neighbor.*, users.email as poster_email, 
         users.first_names || ' ' || users.last_name as poster_name
    from neighbor_to_neighbor, users
   where neighbor_to_neighbor_id = :neighbor_to_neighbor_id
     and neighbor_to_neighbor.poster_user_id = users.user_id"

if {![db_0or1row select_entry $sql_query]} {
    doc_return  200 text/html [neighbor_error_page 1 "<li>Could not find a posting with an id of $neighbor_to_neighbor_id"]
    return
}

# found the row

set page_content "[neighbor_header "$about : $one_line"]

<h2>$about : $one_line</h2>

posted by $poster_email ($poster_name) on $posted

<hr>

<h3>Story</h3>

$full_description_text
<form action=edit-3 method=post>
<center>
[export_form_vars neighbor_to_neighbor_id]
<input type=submit name=edit_or_delete value=\"Edit\">
<input type=submit name=edit_or_delete value=\"Delete\">
</center>
</form>

[neighbor_footer]
"

db_release_unused_handles
doc_return 200 text/html $page_content
