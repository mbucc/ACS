# /admin/ug/group-info-edit.tcl
ad_page_contract {
    @param group_id the ID of the group
    
    @cvs-id group-info-edit.tcl,v 3.4.2.7 2000/12/16 01:51:42 cnk Exp
} {
    group_id:notnull,naturalnum
}

set user_id [ad_get_user_id]
if {$user_id == 0} {
   ad_returnredirect /register?return_url=[ns_urlencode "/admin/ug/group?[export_url_vars group_id]"]
    return
}


db_1row group_type_name_get "select group_type, group_name
from user_groups where group_id = :group_id"


set info_table_name [string toupper [ad_user_group_helper_table_name $group_type]]

set page_content "[ad_admin_header "Edit $group_name"]

<h2>Edit information</h2>

for <a href=\"group?[export_url_vars group_id]\">$group_name</a>

<hr>
<form method=POST action=\"group-info-edit-2\">
[export_form_vars group_id]
<table>"

# need to figure out if any of the extra columns can be edited from
# this interface and remove the submit button if not
set number_of_editable_columns 0

if { [db_string select_table_exists "select count(*) from user_tables where table_name=:info_table_name"] > 0 } {

    db_foreach group_columns "select column_name, pretty_name, column_type from user_group_type_fields where group_type = :group_type order by sort_key" {

	set $column_name [db_string select_column_val "select $column_name from $info_table_name where group_id = :group_id" -default ""]

	append page_content "<tr><th>$pretty_name</th><td> [ad_user_group_type_field_form_element "group_info.$column_name" $column_type [set $column_name]]</td></tr>\n"

	if { ![string match $column_type "special"] } {
	    incr number_of_editable_columns
	}

    }
    
}
 
append page_content "
</table>
"
if { $number_of_editable_columns > 0 } {
    append page_content "
<p>
<center>
<input type=submit value=\"Update\">
</center>
" 
} else {
    append page_content "
<p> The column types for all of the fields listed above were all defined
as \"special\", which prevents anyone from editing them from this
interface. If you need to change that behavior you will need to alter
the column_type definition of these columns in the user_group_type_fields 
meta-data table.
" 
}

append page_content "
</form>

[ad_admin_footer]
"

# serve the page
doc_return  200 text/html $page_content

