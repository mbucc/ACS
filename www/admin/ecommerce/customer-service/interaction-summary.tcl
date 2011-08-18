# $Id: interaction-summary.tcl,v 3.0 2000/02/06 03:17:57 ron Exp $
set_the_usual_form_variables
# user_id or user_interaction_id

ReturnHeaders

set page_title "Interaction Summary"
ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>

<b>Customer:</b> 
"

set db [ns_db gethandle]

if { [info exists user_id] } {
    ns_write "Registered user: <a href=\"/admin/users/one.tcl?user_id=$user_id\">[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$user_id"]</a>"
} else {
    ns_write "[ec_user_identification_summary $db $user_identification_id]"
}

ns_write "<p>
<center>
"

if { [info exists user_id] } {

    set selection [ns_db select $db "select a.issue_id, a.action_id, a.interaction_id, a.action_details, a.follow_up_required, i.customer_service_rep, i.interaction_date, to_char(i.interaction_date,'YYYY-MM-DD HH24:MI:SS') as full_interaction_date, i.interaction_originator, i.interaction_type, reps.first_names || ' ' || reps.last_name as rep_name
    from ec_customer_service_actions a, ec_customer_serv_interactions i, ec_user_identification id, users reps
    where a.interaction_id=i.interaction_id
    and i.user_identification_id=id.user_identification_id
    and id.user_id=$user_id
    and i.customer_service_rep = reps.user_id(+)
    order by a.action_id desc"]

} else {
    set selection [ns_db select $db "select a.issue_id, a.action_id, a.interaction_id, a.action_details, a.follow_up_required, i.customer_service_rep, i.interaction_date, to_char(i.interaction_date,'YYYY-MM-DD HH24:MI:SS') as full_interaction_date, i.interaction_originator, i.interaction_type, reps.first_names || ' ' || reps.last_name as rep_name
    from ec_customer_service_actions a, ec_customer_serv_interactions i, ec_user_identification id
    where a.interaction_id=i.interaction_id
    and i.user_identification_id=$user_identification_id
    and i.customer_service_rep = reps.user_id
    order by a.action_id desc"]
}

set old_interaction_id ""
set action_counter 0
while { [ns_db getrow $db $selection] } {
    incr action_counter
    set_variables_after_query

    if { [string compare $interaction_id $old_interaction_id] != 0 } {
	ns_write "<p>
	<table width=90% bgcolor=\"ececec\"><tr><td>

	<b>[ec_formatted_full_date $full_interaction_date]</b><br>
	<table>
	<tr><td align=right><b>Rep</td><td><a href=\"/admin/users/one.tcl?user_id=$customer_service_rep\">$rep_name</a></td></tr>
	<tr><td align=right><b>Originator</td><td>$interaction_originator</td></tr>
	<tr><td align=right><b>Via</td><td>$interaction_type</td></tr>
	</table>

	</td></tr></table>
	"
    }


    ns_write "<p>
    <table width=90%>
    <tr bgcolor=\"ececec\"><td>Issue ID: <a href=\"issue.tcl?issue_id=$issue_id\">$issue_id</a></td></tr>
    <tr><td>
    <blockquote>
    <b>Details:</b>
    <blockquote>
    [ec_display_as_html $action_details]
    </blockquote>
    </blockquote>
    </td></tr>
    "
    if { ![empty_string_p $follow_up_required] } {
	ns_write "<tr><td>
	<blockquote>
	<b>Follow-up Required</b>:
	<blockquote>
	[ec_display_as_html $follow_up_required]
	</blockquote>
	</blockquote>
	</td></tr>
	"
    }
    ns_write "</table>
    "

    set old_interaction_id $interaction_id
}

ns_write "</center>
[ad_admin_footer]
"