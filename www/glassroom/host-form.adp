<%
# host-form.adp -- an incldued file for host-edit.adp and host-add.adp which
#                  shares the form between those two pages.
#
# required arguments - the text for the "submit button" and the action
#                      for the form


if { [ns_adp_argc] != 3 } {
    ns_log error "wrong number of arguments passed to host-form.adp.  The text for the submit button should be included, as well as the form action to send the data to."
    ns_adp_abort
}

ns_adp_bind_args submit_button_text form_action

# make sure these variables exist so we don't generate lots of errors
# accessing unknown variables below

if { ![info exists hostname] } {
    set hostname ""
}

if { ![info exists ip_address] } {
    set ip_address ""
}

if { ![info exists os_version] } {
    set os_version ""
}

if { ![info exists description] } {
    set description ""
}

if { ![info exists model_and_serial] } {
    set model_and_serial ""
}

if { ![info exists street_address] } {
    set street_address ""
}

if { ![info exists remote_console_instructions] } {
    set remote_console_instructions ""
}

if { ![info exists service_phone_number] } {
    set service_phone_number ""
}

if { ![info exists service_contract] } {
    set service_contract ""
}

if { ![info exists facility_phone] } {
    set facility_phone ""
}

if { ![info exists facility_contact] } {
    set facility_contact ""
}

if { ![info exists backup_strategy] } {
    set backup_strategy ""
}

if { ![info exists rdbms_backup_strategy] } {
    set rdbms_backup_strategy ""
}

if { ![info exists further_docs_url] } {
    set further_docs_url ""
}


%>

<%=[glassroom_form_action "$form_action" ]%>

<%
if { [info exists host_id] } {
    ns_puts "[export_form_vars host_id]\n"
}
%>

<table>

<tr>
  <td align=right> Main Hostname: 
  <td>             <input type=text size=30 name=hostname <%= [export_form_value hostname] %>>
</tr>


<tr>
  <td align=right> IP Address: 
  <td>             <input type=text size=15 name=ip_address <%= [export_form_value ip_address] %>>
</tr>



<tr>
  <td align=right> Operating System and Version: 
  <td>             <input type=text size=50 name=os_version <%= [export_form_value os_version] %>>
</tr>



<tr>
  <td align=right valign=top> Description of physical configuration: 
  <td>             <textarea wrap=physcal cols=60 rows=6 name=description><%= [ns_quotehtml $description] %></textarea>
</tr>



<tr>
  <td align=right> Model# and Serial #: 
  <td>             <input type=text size=30 name=model_and_serial <%= [export_form_value model_and_serial] %>>
</tr>



<tr>
  <td align=right valign=top> Street Address:
  <td>             <textarea wrap=soft cols=60 rows=6 name=street_address><%= [ns_quotehtml $street_address] %></textarea>
</tr>


  
<tr>
  <td align=right valign=top> How to get to the console port:
  <td>             <textarea wrap=soft cols=60 rows=6 name=remote_console_instructions><%= [ns_quotehtml $remote_console_instructions] %></textarea>
</tr>



<tr>
  <td align=right> Service contract phone number: 
  <td>             <input type=text size=30 name=service_phone_number <%= [export_form_value service_phone_number] %>>
</tr>



<tr>
  <td align=right valign=top> Service contract number and other details:
  <td>             <textarea wrap=soft cols=60 rows=6 name=service_contract><%= [ns_quotehtml $service_contract] %></textarea>
</tr>


  
<tr>
  <td align=right> Hosting facility phone number: 
  <td>             <input type=text size=30 name=facility_phone <%= [export_form_value facility_phone] %>>
</tr>



<tr>
  <td align=right> Hosting facility contact information:
  <td>             <input type=text size=60 name=facility_contact <%= [export_form_value facility_contact] %>>
</tr>



<tr>
  <td align=right valign=top> File system backup strategy:
  <td>             <textarea wrap=soft cols=60 rows=6 name=backup_strategy><%= [ns_quotehtml $backup_strategy] %></textarea>
</tr>


        
<tr>
  <td align=right valign=top> RDBMS backup strategy:
  <td>             <textarea wrap=soft cols=60 rows=6 name=rdbms_backup_strategy><%= [ns_quotehtml $rdbms_backup_strategy] %></textarea>
</tr>


<tr>
  <td align=right> Complete URL for other documentation:
  <td>             <input type=text size=60 name=further_docs_url <%= [export_form_value further_docs_url] %>>
</tr>

</table>

<p>
  
<%=[glassroom_submit_button "$submit_button_text" ]%>


</form>

