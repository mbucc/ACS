# /admin/ug/group-info-edit.tcl
#
# author/creation date unknown
#
# $Id: group-info-edit.tcl,v 3.0.4.2 2000/04/28 15:09:27 carsten Exp $

ad_page_variables {group_id}

set user_id [ad_get_user_id]
if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/ug/group.tcl?[export_url_vars group_id]"]
    return
}

set db [ns_db gethandle]

set selection [ns_db 1row $db "select group_type, group_name
from user_groups where group_id = $group_id"]
set_variables_after_query

set info_table_name [ad_user_group_helper_table_name $group_type] 


set page_content "[ad_admin_header "Edit $group_name"]

<h2>Edit information</h2>

for <a href=\"group.tcl?[export_url_vars group_id]\">$group_name</a>

<hr>
<form method=POST action=\"group-info-edit-2.tcl\">
[export_form_vars group_id]
<table>"

if [ns_table exists $db $info_table_name] {
    set selection [ns_db 0or1row $db "select * from $info_table_name where group_id = $group_id"]
    if { $selection != "" } {
	set_variables_after_query
    }
}
	set selection [ns_db select $db "select column_name, pretty_name, column_type from user_group_type_fields where group_type = '[DoubleApos $group_type]' order by sort_key"]
	
	while { [ns_db getrow $db $selection] } {
	    set_variables_after_query
	    #	ns_write "<tr><th>$pretty_name</th><td> <input type=text name=$column_name value=\"[philg_quote_double_quotes [set $column_name]]\"></td></tr>\n"
	    append page_content "<tr><th>$pretty_name</th><td> [ad_user_group_type_field_form_element $column_name $column_type [set $column_name]]</td></tr>\n"
	}
    

 
append page_content "
</table>
<p>
<center>
<input type=submit value=\"Update\">
</center>
</form>


[ad_admin_footer]
"

# release the database handle
ns_db releasehandle $db

# serve the page
ns_return 200 text/html $page_content






