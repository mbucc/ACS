<%
# logbook-form.adp -- an included file for logbook-edit.adp and logbook-add.adp
#                     which shares the form between those two pages
#
# required arguments - the text for the "submit button" and the action
#                      for the form

if { [ns_adp_argc] != 3 } {
    ns_log error "wrong number of arguments passed to release-form.adp. I count [ns_adp_argc].  The text for the submit button should be included, as well as the form action to send the data to."
    ns_adp_abort
}

ns_adp_bind_args submit_button_text form_action

if ![info exists procedure_name] {
    set procedure_name ""
}

%>


<%=[glassroom_form_action "$form_action" ]%>


<table>

<tr>
  <td align=right> Procedure:
  <td>             <select name=procedure_name_select>
                      <option value=""> No Procedure
<%
set name_in_popup_p 0

set select_sql "select procedure_name as procedure_name_db from glassroom_procedures order by procedure_name"
set selection [ns_db select $db $select_sql]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [string compare $procedure_name_db $procedure_name] == 0 } {
	ns_puts "                      <option selected> $procedure_name_db</option>"
	set name_in_popup_p 1
    } else {
	ns_puts "                      <option> $procedure_name_db</option>"
    }
}
%>
                   </select>
   or
<%
if { !$name_in_popup_p } {
    ns_puts "                      <input type=text maxlength=50 name=procedure_name_text [export_form_value procedure_name] >"
} else {
    ns_puts "                      <input type=text maxlength=50 name=procedure_name_text>"
}
%>
</tr>

<tr>
  <td align=right> Notes:
  <td>             <textarea wrap=soft cols=60 rows=6 name=notes><%= [ns_quotehtml $notes] %></textarea>
</tr>

</table>

<p>
  
<%=[glassroom_submit_button "$submit_button_text" ]%>

</form>
