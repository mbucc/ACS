# $Id: transition-add.tcl,v 3.0.4.1 2000/04/28 15:08:32 carsten Exp $
set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}


set_the_usual_form_variables 0
# all optional: from_state, after

if { ![exists_and_not_null after] } {
    set after 0
}

set db [ns_db gethandle]

ReturnHeaders

ns_write "[ad_admin_header "Add a State Transition"]
<h2>Add a State Transition</h2>
[ad_admin_context_bar [list "/admin/crm" CRM] "Add a State Transition"]
<hr>

<form action=\"transition-add-2.tcl\" method=POST>
[export_form_vars from_state after]

<table border=0>
"

set state_name_options [db_html_select_value_options $db "select state_name as state_name_value, state_name as state_name_name from crm_states order by state_name"]

if { ![exists_and_not_null from_state] } {
    ns_write "<tr><th>From <td><select name=from_state>$state_name_options</select></tr>\n"
} else {
    ns_write "<tr><th>From <td>$from_state</tr>\n"
}

ns_write "<tr><th>To <td><select name=to_state>$state_name_options</select></tr>
<tr><th valign=top>Transition Condition
<td><code>update users<br>
set crm_state = <i>to_state</i>, crm_state_entered_date = sysdate<br>
where crm_state = <i>from_state</i><br> and (<br>
<textarea wrap=soft cols=60 rows=5 name=transition_condition></textarea><br>
)</code></tr>
<tr><td colspan=2 align=center><input type=submit value=Add></tr>
</table>
</form>

[ad_admin_footer]
"





