<%
# domain-form.adp -- an incldued file for domain-edit.adp and domain-add.adp
#                    which share the form between those two pages.
#
# required arguments - the text for the "submit" button, and the form-action

# make sure these variables exist so we don't generate lots of errors
# accessing unknown variables below

if { [ns_adp_argc] != 3 } {
    ns_log error "wrong number of arguments passed to domain-form.adp.  The text for the submit button should be included, as well as the form action to send the data to."
    ns_adp_abort
}

ns_adp_bind_args submit_button_text form_action


if { ![info exists domain_name] } {
    set domain_name ""
}

if { ![info exists last_paid] } {
    set last_paid [ns_fmttime [ns_time] "%Y-%m-%d"]
}

if { ![info exists by_whom_paid] } {
    set by_whom_paid ""
}

if { ![info exists expires] } {
    set expires [ns_fmttime [ns_time] "%Y-%m-%d"]
}

%>

<%=[glassroom_form_action "$form_action" ]%>

<% 
if { [info exists domain_name] } {
    set old_domain_name $domain_name
    ns_puts "[export_form_vars old_domain_name]\n"
}
%>

<table>

<tr>
  <td align=right> Domain Name: 
  <td>             <input type=text size=50 name=domain_name maxlength=50 <%= [export_form_value domain_name] %>>
</tr>

<tr>
  <td align=right> Date Last Paid:
  <td>             <%= [philg_dateentrywidget last_paid $last_paid] %>
</tr>

<tr>
  <td align=right> Paid by Whom:
  <td>             <input type=text size=50 name=by_whom_paid maxlength=100 <%= [export_form_value by_whom_paid] %>>
</tr>

<tr>
  <td align=right> Exipiration Date:
  <td>             <%= [philg_dateentrywidget expires $expires] %>
</tr>

</table>

<p>
  
<%=[glassroom_submit_button "$submit_button_text" ]%>

</form>

