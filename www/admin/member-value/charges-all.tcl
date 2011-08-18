# $Id: charges-all.tcl,v 3.0 2000/02/06 03:24:56 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "All Charges for [ad_system_name]"]

<h2>All charges</h2>

[ad_admin_context_bar [list "index.tcl" "Member Value"] "All Charges"]


<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select uc.*, u.first_names || ' ' || u.last_name as user_name, au.first_names || ' ' || au.last_name as administrator_name
from users_charges uc, users u, users au
where uc.user_id = u.user_id
and uc.admin_id = au.user_id(+)
order by entry_date desc"]

set counter 0 
set items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
    append items "<li>$entry_date: <a href=\"user-charges.tcl?user_id=$user_id\">$user_name</a> charged [mv_pretty_amount $currency $amount],
[mv_pretty_user_charge $charge_type $charge_key $charge_comment]
\n"
    if ![empty_string_p $admin_id] {
	append items "by <a href=\"charges-by-one-admin.tcl?admin_id=$admin_id\">$administrator_name</a>"
    }
}

ns_db releasehandle $db

if { $counter == 0 } {
    ns_write "No charges found."
} else {
    ns_write $items
}

ns_write "
</ul>

[ad_admin_footer]
"
