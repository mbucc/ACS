# /www/admin/crm/transition-edit.tcl

ad_page_contract {
    Edit page for crm transition
    @param state_name
    @param next_state
    @author Jin Choi(jsc@arsdigita.com)
    @cvs-id  transition-edit.tcl,v 3.3.2.6 2000/09/22 01:34:38 kevin Exp
} {
    state_name
    next_state
}

set user_id [ad_maybe_redirect_for_registration]

set transition_condition [db_string crm_state_transition "select transition_condition
from crm_state_transitions
where state_name = :state_name
and next_state = :next_state"]



doc_return  200 text/html "[ad_admin_header "Edit State Transition"]
<h2>Edit State Transition</h2>
[ad_admin_context_bar [list "/admin/crm" CRM] "Edit State Transition"]
<hr>

<form action=\"transition-edit-2\" method=POST>
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
