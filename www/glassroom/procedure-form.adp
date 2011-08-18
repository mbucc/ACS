<%
# procedure-form.adp -- an included file for procedure-edit.adp and procedure-add.adp
#                    which shares the form between those two pages
#
# required arguments - the text for the "submit button" and the action
#                      for the form

if { [ns_adp_argc] != 3 } {
    ns_log error "wrong number of arguments passed to procedure-form.adp.  The text for the submit button should be included, as well as the form action to send the data to."
    ns_adp_abort
}

ns_adp_bind_args submit_button_text form_action

if { ![info exists source] } {
    set source ""
}

if ![info exists importance] {
    set importance "1"
}

if ![info exists responsible_user_group] {
    set responsible_user_group ""
}

if ![info exists procedure_description] {
    set procedure_description ""
}

%>


<%= [glassroom_form_action "$form_action"] %>

<%
# keep around the old procedure name if they're going to be editing it
if ![info exists old_procedure_name] {
    ns_puts "[philg_hidden_input old_procedure_name $procedure_name]"
} else {
    ns_puts "[philg_hidden_input old_procedure_name $old_procedure_name]"
}

%>

<table>

<tr>
  <td align=right> Procedure Name: 
  <td>             <input type=text maxlength=50 name=procedure_name size=30 <%= [export_form_value procedure_name] %>>
</tr>

<tr>
  <td align=right valign=top> Procedure Description:
  <td>             <textarea wrap-soft cols=60 rows=6 name=procedure_description><%= [ns_quotehtml $procedure_description] %></textarea>
</tr>

<tr>
  <td align=right> Responsible User:
  <td>             
<%
if { ![info exists responsible_user] || [empty_string_p $responsible_user] } {
    set whom "nobody"
} else {
    set whom [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$responsible_user"]
    ns_puts [export_form_vars responsible_user]
}
ns_puts "<i>$whom</i>"
%>
<input type=submit name=find_responsible_user value="Search for User">

</tr>



<tr>
  <td align=right> Responsible User Group:
  <td>             <select name=responsible_user_group>
<%

if { [empty_string_p $responsible_user_group] } {
    ns_puts "                     <option value=\"\" selected> No Group"
} else {
    ns_puts "                     <option value=\"\">No Group"
}

set selection [ns_db select $db "select group_name, group_id from user_groups order by group_name"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $responsible_user_group == $group_id } {
	ns_puts "                     <option value=$group_id selected> $group_name"
    } else {
	ns_puts "                     <option value=$group_id> $group_name"
    }
}

%>
                   </select>

</tr>


<tr>
  <td align=right> Maximum Time Interval:
  <td>             <input type=text maxlength=8 name=max_time_interval size=10 <%= [export_form_value max_time_interval] %>>

 (days or fractions of days)
</tr>



<tr>
  <td align=right> Importance:
  <td>             <select name=importance>
                     
<%

for { set i 1 } { $i <= 10 } { incr i } {

    if { $i == 1 } {
	set label "$i - Least Important"
    } elseif { $i == 10 } {
	set label "$i - Most Important"
    } else {
	set label $i
    }

    if { [string compare $i $importance] == 0 } {
	ns_puts "                     <option selected value=$i> $label"
    } else {
	ns_puts "                     <option value=$i> $label"
    }

}
ns_puts "<option value=0> 0 -- nuke me"
ns_puts "<option value=11> 11 -- nuke me"
%>
                   </select>
</tr>


</table>

<p>

<%= [glassroom_submit_button "Add Procedure"] %>

</form>


