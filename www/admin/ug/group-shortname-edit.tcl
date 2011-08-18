# $Id: group-shortname-edit.tcl,v 3.0.4.1 2000/04/28 15:09:32 carsten Exp $
set_the_usual_form_variables

# group_id


set user_id [ad_get_user_id]
if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/ug/group.tcl?[export_url_vars group_id]"]
    return
}

set db [ns_db gethandle]

set selection [ns_db 1row $db "select ug.*, first_names, last_name
from user_groups ug, users u
where group_id = $group_id
and ug.creation_user = u.user_id"]
set_variables_after_query

ReturnHeaders 

ns_write "[ad_admin_header "Edit Shortname $short_name"]

<h2>Edit Shortname $short_name</h2>

[ad_admin_context_bar [list "index.tcl" "User Groups"] [list "group-type.tcl?[export_url_vars group_type]" "One Group Type"] [list "group.tcl?group_id=$group_id" "One Group"] "Edit Shortname"]

<hr>

<form method=POST action=\"group-shortname-edit-2.tcl\">
[export_form_vars group_id]
New Shortname:  <input type=text name=short_name size=30 value=\"[philg_quote_double_quotes $short_name]\">
<p>

<input type=submit value=\"Update\">

</form>


[ad_admin_footer]
"
