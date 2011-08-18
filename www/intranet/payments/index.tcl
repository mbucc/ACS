# $Id: index.tcl,v 3.1.4.1 2000/03/17 08:23:07 mbryzek Exp $
# File: /www/intranet/payments/index.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: shows all payments for a specific project
#

set_form_variables 0

# group_id

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set project_name [database_to_tcl_string $db "select 
group_name from user_groups ug
where group_id = $group_id
"]

set selection [ns_db select $db "select 
start_block, fee, fee_type, note, 
decode(paid_p, 't', 'Yes', 'No') as paid_p, 
group_id, payment_id from im_project_payments 
where
group_id = $group_id order by start_block asc"]
 
set payment_text ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append payment_text "<tr>
    <td>[util_IllustraDatetoPrettyDate $start_block]
    <td>$fee_type
    <td>[util_commify_number $fee]
    <td>$paid_p <a href=payment-negation.tcl?[export_url_vars payment_id]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]>toggle</a>
    <td>$note<td><a href=project-payment-ae.tcl?[export_url_vars group_id payment_id]>Edit</a></tr>
<p>"

}

if {$payment_text == ""} {
    set payment_text "There are no payments recorded."
} else {
    set payment_text "
<table cellspacing=5>
<tr>
 <th align=left>Start of work period
 <th align=left>Fee type
 <th align=left>Fee
 <th align=left>Paid?
 <th align=left>Note
 <th align=left>Edit
$payment_text
</table>
"
}

set page_title "Payments for $project_name"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "../projects/index.tcl" "Projects"] [list "../projects/view.tcl?[export_url_vars group_id]"  $project_name] "Payments"]

ns_return 200 text/html "
[ad_partner_header]

Start of work period is the start of actual development.  Typically,
a monthly fee for a given month is due the 15th of the following month.
For example, if the \"start of work period\" is November 1st, the fee for
this is due on December 15th.

$payment_text
<p>
<table width=100%>
<tr>
 <td><a href=project-payment-ae.tcl?[export_url_vars group_id]>Add a payment</a>
 <td align=right><a href=project-payments-audit.tcl?[export_url_vars group_id]>Audit Trail</a>
</table>
[ad_partner_footer]
"
