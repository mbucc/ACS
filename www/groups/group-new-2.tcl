# $Id: group-new-2.tcl,v 3.0.4.1 2000/04/28 15:10:56 carsten Exp $
# File: /groups/group-new-2.tcl
# Date: mid-1998
# Contact: teadams@mit.edu, tarik@mit.edu
# Purpose: creation of a new user group
# 
# Note: groups_public_dir, group_type_url_p, group_type, group_type_pretty_name, 
#       group_type_pretty_plural, group_public_root_url and group_admin_root_url
#       are set in this environment by ug_serve_group_pages. if group_type_url_p
#       is 0, then group_type, group_type_pretty_name and group_type_pretty_plural
#       are empty strings)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables
# group_type, maybe return_url, parent_group_id

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect "/register/index.tcl?return_url=[ad_urlencode "[ug_url]/group-new-2.tcl?group_type=$group_type"]"
    return
}


set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from user_group_types where group_type = '$QQgroup_type'"]

set_variables_after_query

ReturnHeaders 

ns_write "[ad_header "Define a $pretty_name"]

<h2>New $pretty_name</h2>

in <a href=/>[ad_system_name]</a>

<hr>

"

# so we don't get hit by duplicates if the user double-submits,
# let's generate the group_id here

set group_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]

ns_write "
<form method=post action=\"group-new-3.tcl\">
[export_form_vars group_id group_type return_url parent_group_id]
<table>
<tr>
<th>Group Name
<td><input type=text name=group_name>
</tr>

<tr>
<th>Short Name
<td><input type=text name=short_name>
</tr>

<tr>
<th>Group Admin Email
<td><input type=text name=admin_email>
</tr>
"

set approval_widget_raw "
<tr>
<th>New Member Policy
<td><select name=new_member_policy>
<option value=\"open\" selected>Open: Users will be able to join this group
<option value=\"wait\">Wait: Users can apply to join
<option value=\"closed\">Closed: Only administrators can put users in this group 
</select>
</tr>"

set simple_ns_set [ns_set new "Just for approval policy"]
ns_set put $simple_ns_set new_member_policy $default_new_member_policy

set approval_widget_stuffed [bt_mergepiece $approval_widget_raw $simple_ns_set]

ns_write "\n$approval_widget_stuffed\n"



append spam_policy_widget_html "
<tr>
<th>Group Spam Policy
<td><select name=spam_policy>
    [ad_generic_optionlist { "Open : Any group member can spam the group" 
                             "Wait : Spam by members require administrator's approval"
                             "Closed : Only administrators can spam the group" } \
                           { open wait closed } open]
    </select>
</tr>
"

ns_write "\n$spam_policy_widget_html\n"

# now let's query for any additional fields

set selection [ns_db select $db "select * 
from user_group_type_fields
where group_type = '$QQgroup_type'
order by sort_key"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<tr><th>$pretty_name
<td>[ad_user_group_type_field_form_element $column_name $column_type]
</tr>
"
}

ns_write "

</table>
<br>
<center>
<input type=submit value=\"Create\">
</center>
</form>

[ad_footer]
"
