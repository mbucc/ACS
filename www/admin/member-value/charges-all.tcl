# /www/admin/member-value/charges-all.tcl

ad_page_contract {
    
    List all charges on all users.

    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 18:55:52 2000
    @cvs-id charges-all.tcl,v 3.3.2.4 2000/09/22 01:35:31 kevin Exp
} {

}

set page_content "[ad_admin_header "All Charges for [ad_system_name]"]

<h2>All charges</h2>

[ad_admin_context_bar [list "" "Member Value"] "All Charges"]

<hr>

<ul>
"


set sql "select uc.*, u.first_names || ' ' || u.last_name as user_name, au.first_names || ' ' || au.last_name as administrator_name
from users_charges uc, users u, users au
where uc.user_id = u.user_id
and uc.admin_id = au.user_id(+)
order by entry_date desc"

set counter 0 
set items ""
db_foreach mv_users_query $sql {
    incr counter
    append items "<li>$entry_date: <a href=\"user-charges?user_id=$user_id\">$user_name</a> charged [mv_pretty_amount $currency $amount],
[mv_pretty_user_charge $charge_type $charge_key $charge_comment]
\n"
    if ![empty_string_p $admin_id] {
	append items "by <a href=\"charges-by-one-admin?admin_id=$admin_id\">$administrator_name</a>"
    }
}

db_release_unused_handles

if { $counter == 0 } {
    append page_content "No charges found."
} else {
    append page_content $items
}

append page_content "
</ul>

[ad_admin_footer]
"
doc_return  200 text/html $page_content
