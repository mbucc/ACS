# /www/admin/crm/index.tcl

ad_page_contract {
    Let the user define states and transitions for the customer
    relationship manager.

    @author jsc@arsdigita.com
    @cvs-id index.tcl,v 3.4.2.9 2000/09/22 01:34:37 kevin Exp
} {}


set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


append html_string "[ad_admin_header "Customer Relationship States"]
<h2>Customer Relationship States</h2>
[ad_admin_context_bar CRM]
<hr>
Documentation: <a href=\"/doc/crm\">/doc/crm.html</a>

<h3>Possible States</h3>
<blockquote>
"

set state_counter 0
db_foreach crm_states "select state_name, 
description, count(users.crm_state) as n_users
from crm_states, users
where crm_states.state_name = users.crm_state(+)
group by state_name, description
order by state_name" {
    if { $state_counter == 0 } {
	append html_string "<table border=0>
	<tr><th>State Name<th>Description<th>Number of Users</tr>
	"
    }
    incr state_counter
    append html_string "<tr><td>$state_name<td>$description<td><a href=\"/admin/users/action-choose?crm_state=[ns_urlencode $state_name]\">$n_users</tr>\n"
}
if { $state_counter == 0 } {
    append html_string "<p>There are no states.\n"
} else {
    append html_string "</table>"
}

append html_string "</blockquote>
<p>
<a href=\"state-add\">Add a new state</a><br>
<a href=\"run-states\">Run the state machine</a>
"


# If there are users without state, then let the administrator assign them
# to a state.
set n_unstated_users [db_string crm_n_users_without_state "select count(*)
from users
where crm_state is null" -default ""]

set initial_state [db_string crm_initial_state "select state_name
from crm_states
where initial_state_p = 't'" -default ""]

if { $state_counter > 0 } {
    append html_string "<p>
    <form action=\"initial-state-assign\" method=POST>
    Assign new users to: <select name=state>
    <option value=\"\">Select a State</option>
    [db_html_select_options -select_option $initial_state crm_states "select state_name 
    from crm_states
    order by state_name"]
    </select>
    <input type=submit value=\"Assign Initial State\">
    </form>
    "
}

append html_string "
<p> There are $n_unstated_users users who have not been assigned to a state.

<h3>Transitions</h3>
<blockquote>
"

set old_state ""

set counter 0
db_foreach crm_state_transitions "select state_name, 
next_state, triggering_order, transition_condition
from crm_state_transitions
order by state_name, triggering_order" {
    if { $counter == 0 } {
	append html_string "<table border=0 width=90%>
	<tr><th>From<th>To<th>Condition<th></tr>
	"
    }
    incr counter
    if { $old_state != $state_name } {
	append html_string "<tr valign=top><td>$state_name</td>"
	set old_state $state_name
    } else {
	append html_string "<tr valign=top><td>&nbsp;</td>"
    }
    
    append html_string "<td>$next_state</td>
<td><pre>$transition_condition</pre></td>
<td><font size=-1><a href=\"transition-add?from_state=[ns_urlencode $state_name]&after=$triggering_order\">insert after</a><br><a href=\"transition-edit?[export_url_vars state_name next_state]\">edit</a></font></tr>\n"
}
if { $counter == 0 } {
    append html_string "<p> There are no transitions."
} else {
    append html_string "</table>\n"
}
append html_string "</blockquote>

<a href=\"transition-add\">Add a new transition</a>

[ad_admin_footer]
"



doc_return  200 text/html $html_string








