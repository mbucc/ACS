# www/admin/general-comments/integrity-check.tcl

ad_page_contract {
    This page is to verify that the rows that general comments reference
    actually exist, and enable the user to delete any comments that aren't
    tied to anything.

    @cvs-id integrity-check.tcl,v 3.2.2.5 2000/09/22 01:35:24 kevin Exp
} 

set results ""
set counter 0

# Get table name, section name, and primary key for all sections.

db_foreach general_comment_integrity "select m.table_name, section_name, column_name as primary_key_column
from user_constraints uc, user_cons_columns ucc, table_acs_properties m
where ucc.table_name = upper(m.table_name)
and uc.table_name = ucc.table_name
and ucc.constraint_name = uc.constraint_name
and uc.constraint_type = 'P'
order by m.table_name" {

    if { $counter == 0 } {
	append results "<h3>$section_name</h3>\n<ul>\n"
    } else {
	append results "</ul>\n<h3>$section_name</h3>\n<ul>\n"
    }
    incr counter

    db_foreach general_comment_check_individual_integrity "select comment_id, one_line_item_desc from general_comments where on_which_table = :table_name and on_what_id not in (select $primary_key_column from $table_name)" {
	
	append results "<li>$one_line_item_desc <a href=\"integrity-check-delete-comment?[export_url_vars comment_id]\">delete</a>\n"
    }
}

if { $counter > 0 } {
    append results "</ul>"
}

doc_return  200 text/html "[ad_admin_header "General Comments Integrity Check"]

<h2>General Comment Integrity Check</h2>

[ad_admin_context_bar [list "index.tcl" "General Comments"] "Integrity Check"]

<hr>

If an appropriate delete trigger was not created for a module which uses 
general comments, comments may exist for rows which have been deleted.
This page searches out any such rows and lets you delete them.

$results

[ad_admin_footer]
"
