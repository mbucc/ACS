<%
# cert-form.adp -- an incldued file for cert-edit.adp and cert-add.adp which
#                  share the form between those two pages.
#
# required arguments - the text for the "submit" button and the form action

# make sure these variables exist so we don't generate lots of errors
# accessing unknown variables below

if { [ns_adp_argc] != 3 } {
    ns_log error "wrong number of arguments passed to cert-form.adp.  The text for the submit button should be included, as well as the form action to send the data to."
    ns_adp_abort
}

ns_adp_bind_args submit_button_text form_action


if { ![info exists hostname] } {
    set hostname ""
}

if { ![info exists issuer] } {
    set issuer ""
}

if { ![info exists encoded_email] } {
    set encoded_email ""
}

if { ![info exists expires] } {
    set expires [ns_fmttime [ns_time] "%Y-%m-%d"]
}


%>

<%=[glassroom_form_action "$form_action" ]%>

<%
if { [info exists cert_id] } {
    ns_puts "[export_form_vars cert_id]\n"
}
%>

<table>

<tr>
  <td align=right> Hostname: 
  <td>             <input type=text size=30 name=hostname <%= [export_form_value hostname] %>>
</tr>

<tr>
  <td align=right> Issuer:
  <td>             <input type=text size=30 name=issuer <%= [export_form_value issuer] %>>
</tr>

<tr>
  <td align=right> The Certificate Request:
  <td>             <input type=text size=30 maxlength=100 name=encoded_email <%= [export_form_value encoded_email] %>>
</tr>

<tr>
  <td align=right> Exipiration Date:
  <td>             <%= [philg_dateentrywidget expires] %>
</tr>

</table>

<p>
  
<%=[glassroom_submit_button "$submit_button_text" ]%>

</form>

