# /www/intranet/employees/admin/employee-termination.tcl

ad_page_contract {
    Form to fill in termination information
    
    @param user_id The user who is being terminated
    @param return_url The url to return to

    @author mbryzek@arsdigita.com
    @creation-date Sun May 21 23:29:25 2000
    @cvs-id employee-termination.tcl,v 3.7.2.11 2000/09/22 01:38:33 kevin Exp
} {
    user_id:naturalnum
    { return_url "" }
}


ad_maybe_redirect_for_registration

set calling_user_id $user_id



db_1row get_user_info "select first_names, last_name, termination_date, termination_reason from
users, im_employee_info
where users.user_id = :user_id
and users.user_id = im_employee_info.user_id"


if { [empty_string_p $termination_date] } {
    set termination_date 0
}

db_release_unused_handles

set page_title "Edit \"$first_names $last_name\""
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list view.tcl?[export_url_vars user_id] "One employee"] "Edit employee"]




# make sure not to enable cache
ns_set put [ns_conn outputheaders] Pragma no-cache

doc_return 200 text/html "
[im_header]
<form method=post action=employee-termination-2>
[export_form_vars return_url]
<input type=hidden name=dp.im_employee_info.user_id value=$calling_user_id>

We will automatically remove all allocations for this employee starting with the termination date. Note that there is no way to undo an employee's termination.

<table cellpadding=3>

<tr>
  <th align=right>Termination date:</th>
  <td>[ad_dateentrywidget termination $termination_date]</td>
</tr>

<tr>
 <TH align=right valign=top>Termination Reason:</th>
 <TD>
 <textarea name=dp.im_employee_info.termination_reason cols=40 rows=6 wrap=soft>[philg_quote_double_quotes $termination_reason]</TEXTAREA>
 </TD>
</TR>
<tr>
 <TH align=right valign=top>Voluntary Termination:</th>
 <TD>
  <input type=\"radio\" name=dp.im_employee_info.voluntary_termination_p value=\"t\" checked>Yes<br>
  <input type=\"radio\" name=dp.im_employee_info.voluntary_termination_p value=\"f\">No<br>
 </TD>
</TR>
</table>

<P><center>
<input type=submit value=Update>
</center>
</form>


[util_decode $termination_date 0 "" "<p><a href=employee-termination-remove.tcl?[export_url_vars user_id return_url]>Undo this employee's termination</a><p>"]

[ad_footer]
"

## END FILE employee-termination.tcl
