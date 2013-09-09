# /www/admin/crm/state-add.tcl

ad_page_contract {
    @author Jin Choi(jsc@arsdigita.com)
    @cvsid state-add.tcl,v 3.2.6.4 2000/09/22 01:34:38 kevin Exp
} {}

set user_id [ad_maybe_redirect_for_registration]

doc_return  200 text/html "[ad_admin_header "Add a User State"]
<h2>Add a User State</h2>
[ad_admin_context_bar [list "/admin/crm" CRM] "Add a State"]
<hr>

<form action=\"state-add-2\" method=POST>
<table border=0>
<tr><th>State Name<td><input type=text name=state_name size=30></tr>
<tr><th>Description<td><textarea name=description rows=5 cols=60 wrap=soft></textarea></tr>
<tr><td colspan=2 align=center><input type=submit value=\"Add\"></tr>

</table>
</form>

[ad_admin_footer]
"

