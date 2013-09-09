# /www/neighbor/edit-3.tcl

ad_page_contract {
    If edit_or_delete is "Delete", moves the given entry into
    an audit table and deletes it from the live entries.  Otherwise,
    presents the user with a form to edit the entry.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id edit-3.tcl,v 3.3.2.4 2000/09/22 01:38:54 kevin Exp
    @param neighbor_to_neighbor_id the entry to edit or delete
    @param edit_or_delete "Delete" if the entry should be deleted, anything else if it should be edited
} {
    neighbor_to_neighbor_id:integer,notnull
    edit_or_delete:optional
}

set user_id [ad_maybe_redirect_for_registration]

set sql_query "
select * 
from   neighbor_to_neighbor 
where  neighbor_to_neighbor_id = :neighbor_to_neighbor_id"

if {![db_0or1row select_entry $sql_query]} {
    doc_return  200 text/html [neighbor_error_page 1 "<li>Could not find a posting with an id of $neighbor_to_neighbor_id"]
    return
}

# found the row

if { $user_id != $poster_user_id } {
    # not the author
    db_release_unused_handles
    doc_return 200 text/html "[neighbor_header "Permission denied"]

<h2>Permission denied</h2>

to change posting $neighbor_to_neighbor_id ($about : $one_line) 

<P>

in <a href=index>[neighbor_system_name]</a>

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
    db_transaction {
	db_dml add_audit "
          insert into neighbor_to_neighbor_audit 
                      (neighbor_to_neighbor_id, audit_entry_time, domain, 
                       poster_user_id,  posted, primary_category, 
                       subcategory_1, about, one_line, full_description_text)
               select neighbor_to_neighbor_id, sysdate, domain, poster_user_id,
                      posted, primary_category, subcategory_1, about, one_line,
                      full_description_text
                 from neighbor_to_neighbor
                where neighbor_to_neighbor_id = :neighbor_to_neighbor_id"
	db_dml delete_entry "
          delete from neighbor_to_neighbor
                where neighbor_to_neighbor_id = :neighbor_to_neighbor_id"
    }
    db_release_unused_handles
    doc_return 200 text/html "[neighbor_header "Posting Deleted"]

<h2>Posting Deleted</h2>

from <a href=index>[neighbor_system_name]</a>

<hr>

There is not much more to say.

[neighbor_footer]
"

} else {
    # we're doing an edit
    db_release_unused_handles
    doc_return 200 text/html "[neighbor_header "Edit Posting $neighbor_to_neighbor_id"]

<h2>Edit Posting $neighbor_to_neighbor_id</h2>

<hr>

<form action=edit-4 method=GET>
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
