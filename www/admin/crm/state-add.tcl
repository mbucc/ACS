# $Id: state-add.tcl,v 3.0.4.1 2000/04/28 15:08:31 carsten Exp $
set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}

ns_return 200 text/html "[ad_admin_header "Add a User State"]
<h2>Add a User State</h2>
[ad_admin_context_bar [list "/admin/crm" CRM] "Add a State"]
<hr>

<form action=\"state-add-2.tcl\" method=POST>
<table border=0>
<tr><th>State Name<td><input type=text name=state_name size=30></tr>
<tr><th>Description<td><textarea name=description rows=5 cols=60 wrap=soft></textarea></tr>
<tr><td colspan=2 align=center><input type=submit value=\"Add\"></tr>

</table>
</form>

[ad_admin_footer]
"
