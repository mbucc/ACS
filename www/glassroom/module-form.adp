<%
# module-form.adp -- an included file for module-edit.adp and module-add.adp
#                    which shares the form between those two pages
#
# required arguments - the text for the "submit button" and the action
#                      for the form

if { [ns_adp_argc] != 3 } {
    ns_log error "wrong number of arguments passed to module-form.adp.  The text for the submit button should be included, as well as the form action to send the data to."
    ns_adp_abort
}

ns_adp_bind_args submit_button_text form_action

if { ![info exists source] } {
    set source ""
}


%>

<%=[glassroom_form_action "$form_action"]%>

<%= [export_form_vars module_id] %>

<table>

<tr>
  <td align=right> Module Name: 
  <td>             <input type=text maxlength=100 name=module_name <%= [export_form_value module_name] %>>
</tr>


<tr>
  <td align=right> Who Installed It:
  <td>
<%
if { ![info exists who_installed_it] } {
    set whom "nobody"
} else {
    set whom [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$who_installed_it"]
    ns_puts [export_form_vars who_installed_it]
}
ns_puts "<i>$whom</i>"
%>
<input type=submit name=find_who_installed_it value="Search for User">
</tr>



<tr>
  <td align=right> Who Owns It:
  <td>
<%
if { ![info exists who_owns_it] } {
    set whom "nobody"
} else {
    set whom [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$who_owns_it"]
    ns_puts [export_form_vars who_owns_it]
}
ns_puts "<i>$whom</i>"
%>
<input type=submit name=find_who_owns_it value="Search for User">
</tr>


<tr>
<!-- URL, vendor phone number, whatever is necessary to get a new copy -->
  <td align=right> Module Source: 
  <td> <textarea wrap=virtual cols=60 rows=6 name=source><%= [ns_quotehtml $source] %></textarea>
</tr>


<tr>
  <td align=right> Current Version: 
  <td>             <input type=text maxlength=50 name=current_version <%= [export_form_value current_version] %>>
</tr>



</table>

<p>

<%=[glassroom_submit_button $submit_button_text]%>

</form>

