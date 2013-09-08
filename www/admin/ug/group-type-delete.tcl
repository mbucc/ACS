ad_page_contract {
    @param group_type the type of group

    @cvs-id group-type-delete.tcl,v 3.2.2.6 2000/09/22 01:36:14 kevin Exp
} {
    group_type:notnull
}

set pretty_name [db_string get_pretty_name "select pretty_name from user_group_types where group_type = :group_type"]


set page_html "[ad_admin_header "Delete $pretty_name"]

<h2>Delete $pretty_name</h2>

one of <a href=\"index\">the group types</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

This is not an action to be taken lightly.  You are telling the system to 

<ul>
<li>remove the $pretty_name group type
<li>remove all the groups of this type (of which there are currently [db_string get_ug_count "select count(*) from user_groups where group_type = :group_type"])
<li>remove all the user-group mappings for groups of this type (of which there are currently [db_string get_ug_mappings "select count(*) 
from user_groups ug, user_group_map ugm
where ug.group_id = ugm.group_id 
and ug.group_type = :group_type"])

</ul>

<p>

<center>
<form method=GET action=\"group-type-delete-2\">
[export_form_vars group_type]
<input type=submit value=\"Yes, I really want to delete this group type\">
</form>
</center>

[ad_admin_footer]
"

doc_return  200 text/html $page_html
