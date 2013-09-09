ad_page_contract {
    @param group_id the ID of the group
    @param user_id the ID of the user

    @cvs-id membership-refuse.tcl,v 3.2.2.3 2000/09/22 01:36:16 kevin Exp
} {
    group_id:notnull,naturalnum
    user_id:notnull,naturalnum
}

set name [db_string  get_full_name "select first_names || ' ' || last_name from users where user_id = :user_id"]

set group_name [db_string  get_group_name "select group_name from user_groups where group_id = :group_id"]

set page_html "[ad_admin_header "Really refuse $name?"]

<h2> Really refuse $name?</h2>

as a member in <a href=\"group?[export_url_vars group_id]\">$group_name</a>

<hr>

<center>
<table>
<tr><td>
<form method=get action=\"group\">
[export_form_vars group_id]
<input type=submit name=submit value=\"No, Cancel\">
</form>
</td><td>
<form method=get action=\"membership-refuse-2\">
[export_form_vars group_id user_id]
<input type=submit name=submit value=\"Yes, Proceed\">
</form>
</td></tr>
</table>
[ad_admin_footer]
"

doc_return  200 text/html $page_html