# $Id: index.tcl,v 3.0 2000/02/06 03:19:38 ron Exp $
#
# jkoontz@arsdigita.com July 21, 1999
# modified by eveander@arsdigita.com July 23, 1999
#
# This page dislpays the problems in the problem log, if display_all is
# not set then only unresolved problems are displayed

set_form_variables 0
# possibly display_all

ReturnHeaders

ns_write "[ad_admin_header "Potental Problems"]

<h2>Potential Problems</h2>

[ad_admin_context_bar [list "/admin/ecommerce/" Ecommerce] "Potential Problems"]

<hr>
"

set db [ns_db gethandle]
set problem_count [database_to_tcl_string $db "select count(*) from ec_problems_log"]
set unresolved_problem_count [database_to_tcl_string $db "select count(*) from ec_problems_log where resolved_date is null"]

if { ![info exists display_all] } {
    set sql_clause "and resolved_date is null"
    ns_write "
    <b>Unresolved Problems</b> <font size=-1>($unresolved_problem_count)</font> | <a href=\"index.tcl?display_all=true\">All Problems</a> <font size=-1>($problem_count)</font>
    <p>
    "
} else {
    set sql_clause ""
    ns_write "
    <a href=\"index.tcl\">Unresolved Problems</a> <font size=-1>($unresolved_problem_count)</font> | <b>All Problems</b> <font size=-1>($problem_count)</font>
    <p>
    "
}


ns_write "
<ul>
"

set selection [ns_db select $db "select 
 l.*, 
 u.first_names || ' ' || u.last_name as user_name
from ec_problems_log l, users u
where l.resolved_by = u.user_id(+)
$sql_clause
order by problem_date asc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    ns_write "
    <p>
    <li>[util_AnsiDatetoPrettyDate $problem_date] ("

    if { ![empty_string_p $order_id] } {
	ns_write "order #<a href=\"/admin/ecommerce/orders/one.tcl?[export_url_vars order_id]\">$order_id</a> | "
    }

    if { [empty_string_p $resolved_date] } {
	ns_write "<a href=\"resolve.tcl?[export_url_vars problem_id]\">mark resolved</a>"
    } else {
	ns_write "resolved by [ec_admin_present_user $resolved_by $user_name] on [util_AnsiDatetoPrettyDate $resolved_date]"
    }

    ns_write ")
    <p>
    $problem_details
    <p>
    "
}

ns_write "
</ul>

[ad_admin_footer]
"
