# $Id: add.tcl,v 3.0.4.1 2000/03/17 08:23:25 mbryzek Exp $
# File: /www/intranet/vacations/add.tcl
#
# last modified, ahmedaa@mit.edu, December 29 1999
# added vacation_type select box
#
# Purpose: lets a user add info about their absences
#

ad_maybe_redirect_for_registration

set db [ns_db gethandle]
set vacation_id [database_to_tcl_string $db "select user_vacations_vacation_id_seq.nextval
from dual"]


set absence_types [ad_parameter AbsenceTypes pvt "travel sick vacation personal"]

set absence_type_html "<tr><th valign=top align=right>Absence type</th><td><select name=vacation_type>"
set counter 0
foreach ab_type $absence_types {
    append absence_type_html "<option value=$ab_type>$ab_type</option>"
    incr counter
}

append absence_type_html "</select></td></tr>"


if { $counter == 0 } {
    set absence_type_html ""
}

set page_body "
[ad_header "Add a vacation"]

<h2>Add a vacation</h2>

[ad_context_bar [list "../index.tcl" "Intranet"] [list index.tcl "Vacations"] "Add"]

<hr>
<form method=POST action=\"add-2.tcl\"> 
[export_form_vars vacation_id]
<table>
$absence_type_html
<tr><th valign=top align=right>Start date</th>
<td>[philg_dateentrywidget_default_to_today start_date]</td></tr>

<tr><th valign=top align=right>End date</th>
<td>[philg_dateentrywidget_default_to_today end_date]</td></tr>

<tr><th valign=top align=right>Employee</th>
<td>
<select name=user_id>
[im_employee_select_optionlist $db]
</select>
</td>
</tr>

<tr><th valign=top align=right>Description</th>
<td><textarea name=description cols=40 rows=8 wrap=soft></textarea></td></tr>

<tr><th valign=top align=right>Emergency contact information</th>
<td><textarea name=contact_info cols=40 rows=8 wrap=soft></textarea></td></tr>

<tr><th valign=top align=right>Receive email?</th>
<td>Yes <input type=radio name=receive_email_p value=\"t\" checked>
No <input type=radio name=receive_email_p value=\"f\">

</td></tr>

</table>

<p>
<center>
<input type=submit value=\"Add vacation\">
</center>
</form>
<p>
[ad_footer]"

ns_db releasehandle $db

ns_return 200 text/html $page_body 
