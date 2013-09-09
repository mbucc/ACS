# /www/neighbor/edit-4.tcl

ad_page_contract {
    Updates the database with the new neighbor-to-neighbor entry,
    adding a record to the audit table if the difference in the lengths
    of the old and new stories is more than 20 characters.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id edit-4.tcl,v 3.1.6.4 2000/09/22 01:38:55 kevin Exp
    @param neighbor_to_neighbor_id the entry to edit
    @param one_line_from_form a short, one-line description
    @param full_description_from_form the full description
} {
    neighbor_to_neighbor_id:integer,notnull
    one_line_from_form
    full_description_from_form
}

if {![db_0or1row select_entry "
select * 
from   neighbor_to_neighbor 
where  neighbor_to_neighbor_id = :neighbor_to_neighbor_id"]} {
    doc_return  200 text/html [neighbor_error_page 1 "<li>Could not find a posting with an id of $neighbor_to_neighbor_id"]
    return
}

# found the row

set user_id [ad_maybe_redirect_for_registration]

if { $user_id != $poster_user_id } {
    # not the author
    ad_return 200 text/html "
    [neighbor_header "Permission denied"]

    <h2>Permission denied</h2>

    to change posting $neighbor_to_neighbor_id ($about : $one_line) 
    
    <P>
    
    in <a href=index>[neighbor_system_name]</a>
    
    <hr>
    
    <p>You cannot edit or delete this entry because you did not post it.
    
    [neighbor_footer]
    "
    return 
}

# OK, we're authorized, let's do the DML

# first thing to do is decide whether or not to write to audit table

if { [expr abs([string length full_description_text_from_form] - [string length full_description_text])] > 20 } {
    db_dml add_audit "
    insert into neighbor_to_neighbor_audit 
    (neighbor_to_neighbor_id, 
     audit_entry_time, 
     domain, 
     poster_user_id,  
     posted, 
     primary_category, 
     subcategory_1, 
     about, 
     one_line, 
     full_description_text)
    select 
     neighbor_to_neighbor_id, 
     sysdate, 
     domain, 
     poster_user_id, 
     posted, 
     primary_category, 
     subcategory_1, 
     about, 
     one_line, 
     full_description_text
    from  neighbor_to_neighbor
    where neighbor_to_neighbor_id = :neighbor_to_neighbor_id"
}

# do the actual update

# let's make this work with strings > 4000 chars

db_dml update_entry "
update neighbor_to_neighbor
set    one_line = :one_line_from_form,
       full_description_text = empty_clob(),
       poster_user_id = :user_id
where  neighbor_to_neighbor_id = :neighbor_to_neighbor_id
returning full_description_text into :1" -clobs {$full_description_text_from_form}

doc_return  200 text/html "
[neighbor_header "Posting Updated"]

<h2>Posting Updated</h2>

in <a href=index>[neighbor_system_name]</a>

<hr>

<p>There isn't much more to say.  <a
href=\"view-one?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">Click
here</a> if you want to see how the edited posting will look to the
public.

[neighbor_footer]
"
