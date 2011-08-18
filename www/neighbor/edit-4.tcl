# $Id: edit-4.tcl,v 3.0 2000/02/06 03:49:47 ron Exp $
set_the_usual_form_variables

# neighbor_to_neighbor_id, edit_or_delete
# one_line_from_form, full_description_text_from_form

set db [neighbor_db_gethandle]

set selection [ns_db 0or1row $db "select * from neighbor_to_neighbor where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"]
if { $selection == "" } {
    ns_return 200 text/html [neighbor_error_page 1 "<li>Could not find a posting with an id of $neighbor_to_neighbor_id"]
    return
}

set user_id [ad_get_user_id]
# found the row
set_variables_after_query

if { $user_id != $poster_user_id } {
    # not the author
    ns_return 200 text/html "[neighbor_header "Permission denied"]

<h2>Permission denied</h2>

to change posting $neighbor_to_neighbor_id ($about : $one_line) 

<P>

in <a href=index.tcl>[neighbor_system_name]</a>

<hr>

You can not edit or delete this entry because you did not post it.

[neighbor_footer]
"
   return 
}

# OK, we're authorized, let's do the DML

# first thing to do is decide whether or not to write to audit table

if { [expr abs([string length full_description_text_from_form] - [string length full_description_text])] > 20 } {
    ns_db dml $db "insert into neighbor_to_neighbor_audit (neighbor_to_neighbor_id, audit_entry_time, domain, poster_user_id,  posted, primary_category, subcategory_1, about,	one_line, full_description_text)
select neighbor_to_neighbor_id, sysdate, domain, poster_user_id, posted, primary_category, subcategory_1, about, one_line, full_description_text
from neighbor_to_neighbor
where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"
}

# do the actual update

# let's make this work with strings > 4000 chars

ns_ora clob_dml $db "update neighbor_to_neighbor
set one_line = '$QQone_line_from_form',
full_description_text = empty_clob(),
poster_user_id = $user_id
where neighbor_to_neighbor_id = $neighbor_to_neighbor_id
returning full_description_text into :one" $full_description_text_from_form

ns_return 200 text/html "[neighbor_header "Posting Updated"]

<h2>Posting Updated</h2>

in <a href=index.tcl>[neighbor_system_name]</a>

<hr>

There isn't much more to say.  
<a href=\"view-one.tcl?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">Click here</a>
if you want to see how the edited posting will look to the public.

[neighbor_footer]
"
