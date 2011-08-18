# $Id: edit-3.tcl,v 3.1 2000/02/29 04:39:04 jsc Exp $
set_the_usual_form_variables

# neighbor_to_neighbor_id,  edit_or_delete

set db [neighbor_db_gethandle]

set user_id [ad_get_user_id]

set selection [ns_db 0or1row $db "select * from neighbor_to_neighbor where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"]
if { $selection == "" } {
    ns_return 200 text/html [neighbor_error_page 1 "<li>Could not find a posting with an id of $neighbor_to_neighbor_id"]
    return
}

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

if { [info exists edit_or_delete] && $edit_or_delete == "Delete" } {
    # user explicitly requested a deletion
    # let's put the row into an audit table and delete it from
    # the live stuff
    ns_db dml $db "begin transaction"
    ns_db dml $db "insert into neighbor_to_neighbor_audit (neighbor_to_neighbor_id, audit_entry_time, domain, poster_user_id,  posted, primary_category, subcategory_1, about,	one_line, full_description_text)
select neighbor_to_neighbor_id, sysdate, domain, poster_user_id, posted, primary_category, subcategory_1, about,	one_line, full_description_text
from neighbor_to_neighbor
where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"
    ns_db dml $db "delete from neighbor_to_neighbor where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"
    ns_db dml $db "end transaction"
    ns_return 200 text/html "[neighbor_header "Posting Deleted"]

<h2>Posting Deleted</h2>

from <a href=index.tcl>[neighbor_system_name]</a>


<hr>

There is not much more to say.

[neighbor_footer]
"

} else {
    # we're doing an edit
    ns_return 200 text/html "[neighbor_header "Edit Posting $neighbor_to_neighbor_id"]

<h2>Edit Posting $neighbor_to_neighbor_id</h2>

<hr>

<form action=edit-4.tcl method=GET>
<input type=hidden name=neighbor_to_neighbor_id value=\"$neighbor_to_neighbor_id\">

<h3>Summary</h3>

$about : <input type=text name=one_line_from_form size=60 value=\"[philg_quote_double_quotes $one_line]\">

<h3>Full Story</h3>

<textarea name=full_description_text_from_form rows=13 cols=75 wrap=soft>
$full_description_text
</textarea>



<center>
<input type=submit value=\"Edit\">
</center>
</form>

[neighbor_footer]
"
}

