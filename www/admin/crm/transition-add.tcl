# /www/admin/crm/transition-add.tcl

ad_page_contract {
    @param from_stage
    @param after
    @author Jin Choi(jsc@arsdigita.com)
    @cvs-id transition-add.tcl,v 3.3.2.7 2000/09/22 01:34:38 kevin Exp
} {
    from_stage:optional
    after:optional
}

set user_id [ad_maybe_redirect_for_registration]

if { ![exists_and_not_null after] } {
    set after 0
}

append html_string "[ad_admin_header "Add a State Transition"]
<h2>Add a State Transition</h2>
[ad_admin_context_bar [list "/admin/crm" CRM] "Add a State Transition"]
<hr>

<form action=\"transition-add-2\" method=POST>
[export_form_vars from_state after]

<table border=0>
"

set state_name_options [db_html_select_value_options crm_states "select state_name as state_name_value, state_name as state_name_name from crm_states order by state_name"]

if { ![exists_and_not_null from_state] } {
    append html_string "<tr><th>From <td><select name=from_state>$state_name_options</select></tr>\n"
} else {
    append html_string "<tr><th>From <td>$from_state</tr>\n"
}

append html_string "<tr><th>To <td><select name=to_state>$state_name_options</select></tr>
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


doc_return  200 text/html $html_string