#
# admin/gp/find-group.tcl
# mark@ciccarello.com
# February, 2000
#

set_the_usual_form_variables

#
# expects: table_name, row_id
#

ReturnHeaders

set html "[ad_admin_header  "General Permissions Administration" ]
<h2>General Permissions Administration</h2>
[ad_admin_context_bar { "index.tcl" "General Permissions"} "Find Group"]
<hr>
<p>
Please select a user group on which to set permissions:<p>
"

set db [ns_db gethandle]

set selection [ns_db select $db "
    select
        group_name,
        group_id
    from
        user_groups
    order by
        group_name
"]


while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append html "<a href=\"one-group.tcl?[export_url_vars group_id table_name row_id]\">$group_name</a><br>"
}

ns_db releasehandle $db

append html [ad_admin_footer]

ns_write $html








