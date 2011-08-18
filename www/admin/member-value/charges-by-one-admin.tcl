# $Id: charges-by-one-admin.tcl,v 3.0 2000/02/06 03:24:57 ron Exp $
set_the_usual_form_variables

# admin_id

set db [ns_db gethandle]

set admin_name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $admin_id"]

ReturnHeaders

ns_write "[ad_admin_header "All charges by $admin_name"]

<h2>All charges imposed by $admin_name</h2>

[ad_admin_context_bar [list "index.tcl" "Member Value"] "Charges by one admin"]

<hr>

<ul>

"

set selection [ns_db select $db "select uc.*, u.first_names || ' ' || u.last_name as user_name
from users_charges uc, users u
where uc.user_id = u.user_id
and uc.admin_id = $admin_id
order by entry_date desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li>$entry_date: <a href=\"user-charges.tcl?user_id=$user_id\">$user_name</a> charged [mv_pretty_amount $currency $amount],
[mv_pretty_user_charge $charge_type $charge_key $charge_comment]
\n"
}

ns_write "
</ul>

[ad_admin_footer]
"
