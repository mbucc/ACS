<%
# release-form.adp -- an included file for release-edit.adp and release-add.adp
#                    which shares the form between those two pages
#
# required arguments - the text for the "submit button" and the action
#                      for the form

if { [ns_adp_argc] != 3 } {
    ns_log error "wrong number of arguments passed to release-form.adp.  The text for the submit button should be included, as well as the form action to send the data to."
    ns_adp_abort
}

ns_adp_bind_args submit_button_text form_action

if { ![info exists source] } {
    set source ""
}



if { ![info exists release_date] || [empty_string_p $release_date] } {
    set release_date [ns_fmttime [ns_time] "%Y-%m-%d"]
}

if { ![info exists anticipated_release_date] || [empty_string_p $release_date] } {
    set anticipated_release_date [ns_fmttime [ns_time] "%Y-%m-%d"]
}

if { ![info exists module_id] } {
    set module_id ""
}

%>

<%[glassroom_form_action "$form_action" ]%>

<%= [export_form_vars release_id] %>


<table>

<tr>
  <td align=right> Release Name: 
  <td>             <input type=text maxlength=50 name=release_name <%= [export_form_value release_name] %>>
</tr>

<tr>
  <td align=right> Software Module:
  <td>             <select name=module_id>

<%
set select_sql "select module_name, module_id as module_id_from_db from glassroom_modules order by module_name"
set selection [ns_db select $db $select_sql]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $module_id_from_db == $module_id } {
	ns_puts "                     <option value=$module_id selected>$module_name</option>"
    } else {
	ns_puts "                     <option value=$module_id_from_db>$module_name</option>"
    }
}
%>
                   </select>
</tr>


<tr>
  <td align=right> Manager:
  <td>             
<%
if { ![info exists manager] || [empty_string_p $manager] } {
    set whom "nobody"
} else {
    set whom [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$manager"]
    ns_puts [export_form_vars manager]
}
ns_puts "<i>$whom</i>"
%>
<input type=submit name=find_manager value="Search for User">

</tr>


<tr>
  <td align=right> Anticiapted Release Date:
  <td>             <%= [philg_dateentrywidget anticipated_release_date $anticipated_release_date] %>
</tr>


<tr>
  <td align=right> Release Date:
  <td>             <%= [philg_dateentrywidget release_date $release_date] %>

<%
if [info exists actually_released] {
    ns_puts "<input type=checkbox name=actually_released value=checked checked>Actually Released?"
} else {
    ns_puts "<input type=checkbox name=actually_released value=checked>Actually Released?"
}
%>
</tr>

</table>

<p>


<%= [glass_room_submit_button "$submit_button_text"] %>

</form>

