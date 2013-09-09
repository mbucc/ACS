# File: /groups/group-new-2.tcl
ad_page_contract {
    @param group_type the type of group
    @param return_url the url to send the user back to
    @param parent_group_id the parent group

    @cvs-id group-new-2.tcl,v 3.4.2.8 2001/01/10 21:18:36 khy Exp

 Purpose: creation of a new user group
 
 Note: groups_public_dir, group_type_url_p, group_type, group_type_pretty_name, 
       group_type_pretty_plural, group_public_root_url and group_admin_root_url
       are set in this environment by ug_serve_group_pages. if group_type_url_p
       is 0, then group_type, group_type_pretty_name and group_type_pretty_plural
       are empty strings)
} {
    group_type:notnull
    return_url:optional
    parent_group_id:optional
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]

ad_maybe_redirect_for_registration

if {![ad_allow_group_type_creation_p $user_id $group_type]} {
    ad_return_complaint "Group Type Unavailable" "You are trying to create
    a new user group for a group type that is closed or invalid.  Only
    site-wide administrators can create a user group for a closed group type."
    return
}

db_1row get_ugt_info {
    select pretty_name, default_new_member_policy
    from   user_group_types
    where  group_type = :group_type
}

set page_html "[ad_header "Define a $pretty_name"]

<h2>New $pretty_name</h2>

in <a href=/>[ad_system_name]</a>

<hr>

"

# so we don't get hit by duplicates if the user double-submits,
# let's generate the group_id here

set group_id [db_string get_ugseq_nextval "select user_group_sequence.nextval from dual"]

append page_html "
<form method=post action=\"group-new-3\">
[export_form_vars group_type return_url parent_group_id]
[export_form_vars -sign group_id]
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

append page_html "\n$approval_widget_stuffed\n"

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

append page_html "\n$spam_policy_widget_html\n"

# now let's query for any additional fields

db_foreach get_ugt_fields "select column_name, pretty_name, column_type
from user_group_type_fields
where group_type = :group_type
order by sort_key" {

    append page_html "<tr><th>$pretty_name
    <td>[ad_user_group_type_field_form_element "custom.${column_name}" $column_type]
</tr>
"
}
set custom_fields [db_list get_ugt_field_list "select column_name from user_group_type_fields where group_type = :group_type
order by sort_key"]

append page_html "
[export_form_vars custom_fields]

</table>
<br>
<center>
<input type=submit value=\"Create\">
</center>
</form>

[ad_footer]
"
doc_return  200 text/html $page_html