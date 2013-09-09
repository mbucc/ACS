ad_page_contract {
    @param group_id is the ID of the group
    
    @cvs-id group-name-edit.tcl,v 3.3.2.6 2000/09/22 01:36:13 kevin Exp
} {
    group_id:notnull,naturalnum
}


set user_id [ad_get_user_id]
if {$user_id == 0} {
   ad_returnredirect /register?return_url=[ns_urlencode "/admin/ug/group?[export_url_vars group_id]"]
    return
}


db_1row get_group_info "select ug.group_name, ug.group_type, first_names, last_name
from user_groups ug, users u
where group_id = :group_id
and ug.creation_user = u.user_id"


set page_html "[ad_admin_header "Rename $group_name"]

<h2>Rename $group_name</h2>

[ad_admin_context_bar [list "index" "User Groups"] [list "group-type?[export_url_vars group_type]" "One Group Type"] [list "group?group_id=$group_id" "One Group"] "Rename"]

<hr>

<form method=POST action=\"group-name-edit-2\">
[export_form_vars group_id]
New Name:  <input type=text name=group_name size=30 value=\"[philg_quote_double_quotes $group_name]\">
<p>
<center>
<input type=submit value=\"Update\">
</center>
</form>

[ad_admin_footer]
"
doc_return  200 text/html $page_html