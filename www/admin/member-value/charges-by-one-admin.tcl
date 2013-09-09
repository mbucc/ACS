# /www/admin/member-value/charges-by-one-admin.tcl

ad_page_contract {
    List all charges imposed by one admin.
    @param admin_id
    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 19:20:05 2000
    @cvs-id charges-by-one-admin.tcl,v 3.2.2.6 2000/09/22 01:35:31 kevin Exp

} {
    admin_id:integer,notnull
}

set admin_name [db_string mv_get_user_name "select first_names || ' ' || last_name from users where user_id = :admin_id"]

set page_content "[ad_admin_header "All charges by $admin_name"]

<h2>All charges imposed by $admin_name</h2>

[ad_admin_context_bar [list "" "Member Value"] "Charges by one admin"]

<hr>

<ul>

"

set sql "select uc.*, u.first_names || ' ' || u.last_name as user_name
from users_charges uc, users u
where uc.user_id = u.user_id
and uc.admin_id = :admin_id
order by entry_date desc"

db_foreach select_uc_info $sql { 
    append page_content "<li>$entry_date: <a href=\"user-charges?user_id=$user_id\">$user_name</a> charged [mv_pretty_amount $currency $amount],
[mv_pretty_user_charge $charge_type $charge_key $charge_comment]
\n"
}

db_release_unused_handles

append page_content "
</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_content