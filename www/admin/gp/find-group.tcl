ad_page_contract {
    Finds a user group on which to set permissions.

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id find-group.tcl,v 3.3.2.3 2000/07/21 03:57:24 ron Exp
} {
    table_name:notnull
    row_id:notnull
}

ReturnHeaders

set html "[ad_admin_header  "General Permissions Administration" ]
<h2>General Permissions Administration</h2>
[ad_admin_context_bar { "index.tcl" "General Permissions"} "Find Group"]
<hr>
<p>
Please select a user group on which to set permissions:<p>
"



db_foreach group_select "select group_name, group_id
                         from user_groups
                         order by group_name" {
     append html "<a href=\"one-group?[export_url_vars group_id table_name row_id]\">$group_name</a><br>"
}
			 
db_release_unused_handles

append html [ad_admin_footer]

ns_write $html

