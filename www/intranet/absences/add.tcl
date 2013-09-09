

# /www/intranet/absences/add.tcl

ad_page_contract {
    Shows table of Employee, Absence type, Date of abscence, duration
    of absence.  Lets a user add info about their absences
    last modified, ahmedaa@mit.edu, December 29 1999
    added vacation_type select box

    @param user_id User ID
    @param return_url
 
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @cvs-id add.tcl,v 1.6.2.6 2000/07/24 18:20:50 mshurpik Exp   
} {
    { user_id:naturalnum "" }
    { return_url "" }
}


set vacation_id [db_nextval "user_vacations_vacation_id_seq"]

set absence_types [ad_parameter AbsenceTypes pvt "travel sick vacation personal"]

set absence_type_html "
<tr>
  <th valign=top align=right>Absence type</th>
  <td><select name=vacation_type>
"

set counter 0
foreach ab_type $absence_types {
    append absence_type_html "  <option [export_form_value ab_type]>$ab_type</option>\n"
    incr counter
}

append absence_type_html "</select></td>\n</tr>\n"

if { $counter == 0 } {
    set absence_type_html ""
}

# show mini calendars for up to 4 months from now

db_1row future_months_julian_dates \
	"select trunc(add_months(sysdate,1)) as next_month_julian_date_1,
                trunc(add_months(sysdate,2)) as next_month_julian_date_2,
                trunc(add_months(sysdate,3)) as next_month_julian_date_3
           from dual"

set page_title "Add an absence"
set context_bar [ad_context_bar_ws [list ./ "Work absences"] "Add"]

set page_body "
[im_header]
<table><tr><td valign=top align=left>
<!-- This column contains the form to enter information about the work absence -->

<form method=POST action=\"add-2\"> 
[export_form_vars -sign vacation_id]
[export_form_vars return_url]
<table>
$absence_type_html
<tr><th valign=top align=right>Start date</th>
<td>[philg_dateentrywidget_default_to_today start_date]</td></tr>
<tr><th valign=top align=right>End date</th>
<td>[philg_dateentrywidget_default_to_today end_date]</td></tr>

<tr><th valign=top align=right>Employee(s)</th>
<td>
<select name=user_id_list size=5 multiple>
<option value=\"\"> -- Please Select --
[im_employee_select_optionlist $user_id]
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
<input type=submit value=\"Add\">
</center>
</form>

</td><td width=25>&nbsp;</td><td valign=top align=right>

[calendar_small_month]
[calendar_small_month -date $next_month_julian_date_1]
[calendar_small_month -date $next_month_julian_date_2]
[calendar_small_month -date $next_month_julian_date_3]

</td></tr></table>
<p>
[im_footer]"



doc_return  200 text/html $page_body 
