# /www/bboard/admin-update-primary-maintainer.tcl
ad_page_contract {
    Form to update the maintainer of a bboard

    @cvs-id admin-update-primary-maintainer.tcl,v 3.1.6.5 2000/09/22 01:36:46 kevin Exp
} {
    topic
    topic_id:notnull,integer
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

doc_return  200 text/html "
[ad_admin_header "Change primary maintainer for $topic"]

<h2>Change primary maintainer</h2>

for \"$topic\"

<hr>

Current Maintainer:  [db_string current_maintainer "
select first_names || ' ' || last_name || ' ' || '(' || email || ')' 
from users 
where user_id = :primary_maintainer_id"]

<p>

Search for a new user to be primary administrator of this forum by<br>
<form action=\"/user-search\" method=POST>
[export_form_vars topic topic_id]
<input type=hidden name=target value=\"/bboard/admin-update-primary-maintainer-2.tcl\">
<input type=hidden name=passthrough value=\"topic_id\">
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<center>
<input type=submit value=\"Search\">
</center>
</form>

[ad_admin_footer]
"

