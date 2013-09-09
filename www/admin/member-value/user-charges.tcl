# /www/admin/member-value/user-charges.tcl

ad_page_contract {
    List all the charges on this particular user and allow the admin to add a misc charge.
    @param user_id
    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 19:13:21 2000
    @cvs-id user-charges.tcl,v 3.3.2.5 2000/09/22 01:35:32 kevin Exp

} {
    user_id:integer,notnull
}


set selection [db_1row mv_get_user_name "select first_names, last_name from users where user_id = :user_id"]

set page_content "[ad_admin_header "Charges for $first_names $last_name"]

<h2>Charge history</h2>

[ad_admin_context_bar [list "" "Member Value"] "Charges for one user"]

<hr>

User: <a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a>

<p>

Add a miscellaneous charge:

<form method=POST action=\"add-charge\">
<input type=hidden name=user_id value=\"$user_id\">
<input type=hidden name=charge_type value=\"miscellaneous\">
<table>
<tr>
<th>Amount:
<td><input type=text size=7 name=amount>
</tr>
<tr>
<th>Comment
<th><input type=text name=charge_comment size=50>
</tr>
</table>
<center>
<input type=submit value=\"Add\">
</center>
</form>

<h3>Older Charges</h3>

<ul>

"

set sql "select 
  uc.entry_date, 
  uc.charge_type, 
  uc.currency, 
  uc.amount,
  uc.charge_comment,
  uc.admin_id,
  u.first_names || ' ' || u.last_name as admin_name
from users_charges uc, users u
where uc.user_id = :user_id
and uc.admin_id = u.user_id
order by uc.entry_date desc"

set items ""
db_foreach mv_uc_info_query $sql {
    append items "<li>$entry_date: $charge_type $currency $amount, 
by <a href=\"/admin/member-value/charges-by-one-admin?admin_id=$admin_id\">$admin_name</a>"
    if ![empty_string_p $charge_comment] {
	append items " ($charge_comment)"
    } 
    append items "\n"
}

db_release_unused_handles

if { [empty_string_p $items] } {
    append page_content "no charges found"
} else {
    append page_content $items
}

append page_content "
</ul>
[ad_admin_footer]
"
doc_return  200 text/html $page_content