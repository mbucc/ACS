# $Id: transition-edit.tcl,v 3.0.4.1 2000/04/28 15:08:32 carsten Exp $
set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}


set_the_usual_form_variables
# state_name, next_state

set db [ns_db gethandle]

set transition_condition [database_to_tcl_string $db "select transition_condition
from crm_state_transitions
where state_name = '$QQstate_name'
and next_state = '$QQnext_state'"]

ReturnHeaders

ns_write "[ad_admin_header "Edit State Transition"]
<h2>Edit State Transition</h2>
[ad_admin_context_bar [list "/admin/crm" CRM] "Edit State Transition"]
<hr>

<form action=\"transition-edit-2.tcl\" method=POST>
[export_form_vars state_name next_state]
<table border=0>
<tr><th>From <td>$state_name</tr>
<tr><th>To <td>$next_state</tr>
<tr><th valign=top>Transition Condition
<td><code>update users<br>
set crm_state = <i>to_state</i>, crm_state_entered_date = sysdate<br>
where crm_state = <i>from_state</i><br> and (<br>
<textarea wrap=soft cols=60 rows=5 name=transition_condition>$transition_condition</textarea><br>
)</code></tr>
<tr><td colspan=2 align=center><input type=submit value=Edit></tr>
</table>
</form>

[ad_admin_footer]
"





