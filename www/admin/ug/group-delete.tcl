ad_page_contract {
    @param group_id the ID of the group to delete

    @cvs-id group-delete.tcl,v 3.3.2.7 2000/09/22 01:36:12 kevin Exp
} {
    group_id:naturalnum,notnull
}


set group_name [db_string groupname_get "select group_name
from user_groups 
where group_id = :group_id" -default ""]

if { [empty_string_p $group_name] } {
    ad_return_complaint 1 "<li> The group you're trying to delete does not exist (<code>group_id</code>: $group_id); please check to make sure somebody hasn't already deleted it"
    return
}


set page_html "[ad_admin_header "Delete group_name"]

<h2>Delete $group_name</h2>

one of <a href=\"index\">the groups</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

You are telling the system to 

<ul>
<li>remove the $group_name group
<li>remove all the user-group mappings for this group (of which there are currently [db_string select_unused "select count(*) 
from user_groups ug, user_group_map ugm
where ug.group_id = ugm.group_id 
and ug.group_id = :group_id"])
<li>remove all the subgroups for this group (of which there are currently [db_string select_subgroups "select count(*) 
from user_groups ug
where parent_group_id = :group_id"])

</ul>

<p>

<center>
<form method=GET action=\"group-delete-2\">
[export_form_vars group_id]
<input type=submit value=\"Yes, I really want to delete this group\">
</form>
</center>

[ad_admin_footer]
"
doc_return  200 text/html $page_html