# /admin/crm/index.tcl
# by jsc@arsdigita.com

# Let the user define states and transitions for the customer
# relationship manager.

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}

ReturnHeaders
ns_write "[ad_admin_header "Customer Relationship States"]
<h2>Customer Relationship States</h2>
[ad_admin_context_bar CRM]
<hr>
Documentation: <a href=\"/doc/crm.html\">/doc/crm.html</a>
"

set db [ns_db gethandle]


set selection [ns_db select $db "select state_name, description, count(users.crm_state) as n_users
from crm_states, users
where crm_states.state_name = users.crm_state
group by state_name, description
order by state_name"]

ns_write "<h3>Possible States</h3>
<blockquote>
<table border=0>
<tr><th>State Name<th>Description<th>Number of Users</tr>
"

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<tr><td>$state_name<td>$description<td><a href=\"/admin/users/action-choose.tcl?crm_state=[ns_urlencode $state_name]\">$n_users</tr>\n"
}

ns_write "</table>
</blockquote>
<p>

<a href=\"state-add.tcl\">add a new state</a><br>
<a href=\"run-states.tcl\">run the state machine</a>
<p>
"

# If there are users without state, then let the administrator assign them
# to a state.
set n_unstated_users [database_to_tcl_string $db "select count(*)
from users
where crm_state is null"]

set initial_state [database_to_tcl_string_or_null $db "select state_name
from crm_states
where initial_state_p = 't'"]

ns_write "<p>
<form action=\"initial-state-assign.tcl\" method=POST>
Assign new users to: <select name=state>
<option value=\"\">Select a State</option>
[db_html_select_options $db "select state_name 
from crm_states
order by state_name" $initial_state]
</select>
<input type=submit value=\"Assign Initial State\">

</form>

There are $n_unstated_users users who have not been assigned to a state.

<h3>Transitions</h3>
<blockquote>
<table border=0 width=90%>
<tr><th>From<th>To<th>Condition<th></tr>
"


set selection [ns_db select $db "select state_name, next_state, triggering_order, transition_condition
from crm_state_transitions
order by state_name, triggering_order"]

set old_state ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { $old_state != $state_name } {
	ns_write "<tr valign=top><td>$state_name</td>"
	set old_state $state_name
    } else {
	ns_write "<tr valign=top><td>&nbsp;</td>"
    }

    ns_write "<td>$next_state</td>
<td><pre>$transition_condition</pre></td>
<td><font size=-1><a href=\"transition-add.tcl?from_state=[ns_urlencode $state_name]&after=$triggering_order\">insert after</a><br><a href=\"transition-edit.tcl?[export_url_vars state_name next_state]\">edit</a></font></tr>\n"
}

ns_write "</table>
</blockquote>

<a href=\"transition-add.tcl\">add a new transition</a>

[ad_admin_footer]
"
