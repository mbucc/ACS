# $Id: interaction.tcl,v 3.0 2000/02/06 03:17:58 ron Exp $
set_the_usual_form_variables
# interaction_id

ReturnHeaders

set page_title "Interaction #$interaction_id"
ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>

<table>
<tr>
<td align=right><b>Customer</td>
"

set db [ns_db gethandle]
set selection [ns_db 1row $db "select user_identification_id, customer_service_rep, to_char(interaction_date,'YYYY-MM-DD HH24:MI:SS') as full_interaction_date, interaction_originator, interaction_type, interaction_headers from ec_customer_serv_interactions where interaction_id=$interaction_id"]
set_variables_after_query

ns_write "<td>[ec_user_identification_summary $db $user_identification_id]</td>
</tr>
"


ns_write "<tr>
<td align=right><b>Interaction Date</td>
<td>[util_AnsiDatetoPrettyDate [lindex [split $full_interaction_date " "] 0]] [lindex [split $full_interaction_date " "] 1]</td>
</tr>
<tr>
<td align=right><b>Rep</td>
<td><a href=\"/admin/users/one.tcl?user_id=$customer_service_rep\">$customer_service_rep</a></td>
</tr>
<tr>
<td align=right><b>Originator</td>
<td>$interaction_originator</td>
</tr>
<tr>
<td align=right><b>Inquired Via</td>
<td>$interaction_type</td>
</tr>
"

if { ![empty_string_p $interaction_headers] } {
    ns_write "<tr>
    <td align=right><b>Interaction Heade
    <tr>
    <td align=right><b>
    "
}

ns_write "
</table>
<p>
<h3>All actions associated with this interaction</h3>
<center>
"

set selection [ns_db select $db "select a.action_details, a.follow_up_required, a.issue_id
from ec_customer_service_actions a
where a.interaction_id=$interaction_id
order by a.action_id desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<table width=90%>
<tr bgcolor=\"ececec\"><td><b>Issue:</b> <a href=\"issue.tcl?issue_id=$issue_id\">$issue_id</a></td></tr>
<tr><td><b>Details:</b><br><blockquote>[ec_display_as_html $action_details]</blockquote></td></tr>
"
if { ![empty_string_p $follow_up_required] } {
    ns_write "<tr><td colspan=6><b>Follow-up Required:</b><br><blockquote>[ec_display_as_html $follow_up_required]</blockquote></td></tr>
    "
}
ns_write "</table>
<p>
"

}

ns_write "</center>
[ad_admin_footer]
"