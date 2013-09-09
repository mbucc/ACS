# /www/intranet/member-add.tcl

ad_page_contract {
    Presents a search form to find a user to add to a group.

    @param group_id group to which to add
    @param role role in which to add
    @param also_add_to_group_id Additional groups to which to add
    @param return_url Return URL

    @author        mbryzek@arsdigita.com
    @creation-date 16 April 2000
    @cvs-id        member-add.tcl,v 3.5.2.6 2000/09/22 01:38:22 kevin Exp
} {
    group_id:naturalnum
    { role "" }
    { return_url "" }
    { also_add_to_group_id:naturalnum "" }
}

set user_id [ad_maybe_redirect_for_registration]

set group_name [db_string group_name_for_one_group_id \
	"select group_name from user_groups where group_id = :group_id"]

set page_title "Add member to $group_name"
set context_bar [ad_context_bar_ws "Add member"]

set page_content "

Locate your new member by 

<form method=POST action=/user-search>
[export_entire_form]
<input type=hidden name=target value=\"[im_url_stub]/member-add-2\">
<input type=hidden name=passthrough value=\"group_id role return_url also_add_to_group_id\">
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit value=Search>
</center>
</form>
"



doc_return  200 text/html [im_return_template]
