# $Id: edit.tcl,v 3.2.2.1 2000/03/17 08:23:27 mbryzek Exp $
# File: /www/intranet/vacations/edit.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: form to edit a user's absences information
#

# last modified, ahmedaa@mit.edu, December 29 1999
# added vacation_type selection

set_the_usual_form_variables

# vacation_id

set my_user_id [ad_maybe_redirect_for_registration]

set db [ns_db gethandle]

if {[catch {set selection [ns_db 1row $db "
    select start_date, end_date, description, contact_info, user_id, nvl(receive_email_p, 't') as receive_email_p, vacation_type
    from user_vacations 
    where vacation_id = $vacation_id"]} errmsg]} {
    ad_return_error "Error in finding the data" "We encountered an error in querying the database for your object.
Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
} 

set_variables_after_query

# Only the user whose vacation this is, or an administrator, can delete the vacation.
if { $user_id == $my_user_id || [im_is_user_site_wide_or_intranet_admin $db $my_user_id] } {
    set can_delete_p 1
} else {
    set can_delete_p 0
}



set absence_types [ad_parameter AbsenceTypes pvt "travel sick vacation personal"]

set absence_type_html "<tr><th valign=top align=right>Absence type</th><td><select name=vacation_type>"
set counter 0
foreach ab_type $absence_types {
    if { [string compare $ab_type $vacation_type] == 0 } {
	set selected " SELECTED"
    } else {
	set selected ""
    }
    append absence_type_html "<option value=\"$ab_type\"$selected>$ab_type</option>"
    incr counter
}

append absence_type_html "</select></td></tr>"

if { $counter == 0 } {
    set absence_type_html ""
}



#now we have the values from the database.

set page_body "
<h2>Edit the entry for $start_date</h2>

[ad_context_bar [list "../index.tcl" "Intranet"] [list index.tcl "Vacations"] "Add"]

<hr>

<form method=POST action=edit-2.tcl>
[export_form_vars vacation_id]" 

# Make the forms:

append page_body "<table>
$absence_type_html
<tr><th valign=top align=right>Start date</th>

"
if [empty_string_p $start_date] {
    append page_body "<td>No date in the database. Set a date: &nbsp;
    [philg_dateentrywidget_default_to_today start_date]</td></tr>
`
"
} else {
    append page_body "<td>[philg_dateentrywidget start_date $start_date]</td></tr>

"
}

append page_body "<tr><th valign=top align=right>End date</th>
"
if [empty_string_p $end_date] {
    append page_body "<td>No date in the database. Set a date: &nbsp;
    [philg_dateentrywidget_default_to_today end_date]</td></tr>

"
} else {
    append page_body "<td>[philg_dateentrywidget end_date $end_date]</td></tr>

"
}

append page_body "

<tr><th valign=top align=right>Employee</th>
<td>
<select name=user_id>
[im_employee_select_optionlist $db $user_id]
</select>
</td>
</tr>


<tr><th valign=top align=right>Description</th>
<td><textarea name=description cols=40 rows=8 wrap=soft>[ns_quotehtml $description]</textarea></td></tr>

<tr><th valign=top align=right>Emergency contact information</th>
<td><textarea name=contact_info cols=40 rows=8 wrap=soft>[ns_quotehtml $contact_info]</textarea></td></tr>


<tr><th valign=top align=right>Receive email?</th>
<td>Yes [bt_mergepiece "<input type=radio name=receive_email_p value=\"t\">
No <input type=radio name=receive_email_p value=\"f\">" $selection]

</td></tr>

</table>
<p>
<center>
[ad_decode $can_delete_p 1 "
    <input type=button value=\"Delete this vacation\" onClick=\"location.href='delete.tcl?vacation_id=$vacation_id'\">
    <spacer type=horizontal size=50>
" ""]
<input type=submit value=\"Edit vacation\">


</center>
</form>
<p>
[ad_footer]"

ns_db releasehandle $db

ns_return 200 text/html $page_body