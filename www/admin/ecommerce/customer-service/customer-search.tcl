# $Id: customer-search.tcl,v 3.0 2000/02/06 03:17:40 ron Exp $
set_the_usual_form_variables
# amount, days

# error checking
set exception_count 0
set exception_text ""

if { ![info exists amount] || [empty_string_p $amount] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the amount."
} elseif { [regexp {[^0-9\.]} $amount] } {
    incr exception_count
    append exception_text "<li>The amount must be a number (no special characters)."
}

if { ![info exists days] || [empty_string_p $days] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the number of days."
} elseif { [regexp {[^0-9\.]} $days] } {
    incr exception_count
    append exception_text "<li>The number of days must be a number (no special characters)."
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ReturnHeaders
ns_write "[ad_admin_header "Customer Search"]

<h2>Customer Search</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "Customer Search"]

<hr>
Customers who spent more than [ec_pretty_price $amount [ad_parameter Currency ecommerce]] in the last $days days:
<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select unique o.user_id, u.first_names, u.last_name, u.email
from ec_orders o, users u
where o.user_id=u.user_id
and o.order_state not in ('void','in_basket')
and sysdate - o.confirmed_date <= $days
and $amount <= (select sum(i.price_charged) from ec_items i where i.order_id=o.order_id and (i.item_state is null or i.item_state not in ('void','received_back')))
"]

set user_id_list [list]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> ($email)"
    lappend user_id_list $user_id
}


if { [llength $user_id_list] == 0 } {
    ns_write "None found."
} 

ns_write "</ul>
"

if { [llength $user_id_list] != 0 } {
    ns_write "<a href=\"spam-2.tcl?show_users_p=t&[export_url_vars user_id_list]\">Spam these users</a>"
}

ns_write "[ad_admin_footer]
"