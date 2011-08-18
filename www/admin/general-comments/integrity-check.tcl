# $Id: integrity-check.tcl,v 3.0 2000/02/06 03:23:29 ron Exp $
# This page is to verify that the rows that general comments reference
# actually exist, and enable the user to delete any comments that aren't
# tied to anything. This can happen when 

set dbs [ns_db gethandle main 2]
set db [lindex $dbs 0]
set sub_db [lindex $dbs 1]

# Get table name, section name, and primary key for all sections.
set selection [ns_db select $db "select m.table_name, section_name, column_name as primary_key_column
from user_constraints uc, user_cons_columns ucc, table_acs_properties m
where ucc.table_name = upper(m.table_name)
and uc.table_name = ucc.table_name
and ucc.constraint_name = uc.constraint_name
and uc.constraint_type = 'P'
order by m.table_name"]


set results ""

set counter 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { $counter == 0 } {
	append results "<h3>$section_name</h3>\n<ul>\n"
    } else {
	append results "</ul>\n<h3>$section_name</h3>\n<ul>\n"
    }
    incr counter

    set sub_selection [ns_db select $sub_db "select comment_id, one_line_item_desc from general_comments where on_which_table = '$table_name' and on_what_id not in (select $primary_key_column from $table_name)"]
    
    while { [ns_db getrow $sub_db $sub_selection] } {
	set_variables_after_subquery
	
	append results "<li>$one_line_item_desc <a href=\"integrity-check-delete-comment.tcl?[export_url_vars comment_id]\">delete</a>\n"
    }

}
if { $counter > 0 } {
    append results "</ul>"
}

ns_db releasehandle $db
ns_db releasehandle $sub_db

ns_return 200 text/html "[ad_admin_header "General Comments Integrity Check"]
<h2>General Comment Integrity Check</h2>

[ad_admin_context_bar [list "index.tcl" "General Comments"] "Integrity Check"]

<hr>

If an appropriate delete trigger was not created for a module which uses 
general comments, comments may exist for rows which have been deleted.
This page searches out any such rows and lets you delete them.

$results

[ad_admin_footer]
"
