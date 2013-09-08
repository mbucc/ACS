# /groups/admin/group/membership-refuse.tcl

ad_page_contract {
    @param user_id user ID of the refusee

    @cvs-id membership-refuse.tcl,v 3.1.6.5 2000/09/22 01:38:12 kevin Exp

    Deny membership to user who applied for it (used only for groups, which heave new members policy set to wait).

 Note: group_id and group_vars_set are already set up in the environment y the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    user_id:notnull,naturalnum
}

set group_name [ns_set get $group_vars_set group_name]
set group_admin_url [ns_set get $group_vars_set group_admin_url]


set name [db_string get_full_name "
select first_names || ' ' || last_name from users where user_id = :user_id"]

 
doc_return  200 text/html "
[ad_scope_admin_header "Really refuse $name?"]
[ad_scope_admin_page_title "Really refuse $name?"]
[ad_scope_admin_context_bar "Refuse $name"]
<hr>

<center>
<table>
<tr><td>
<form method=get action=members>
<input type=submit name=submit value=\"No, Cancel\">
</form>
</td><td>
<form method=get action=\"membership-refuse-2\">
[export_form_vars user_id]
<input type=submit name=submit value=\"Yes, Proceed\">
</form>
</td></tr>
</table>
[ad_scope_admin_footer]
"
