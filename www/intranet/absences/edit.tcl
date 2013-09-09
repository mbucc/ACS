# /www/intranet/absences/edit.tcl

ad_page_contract {
    Purpose: form to edit a user's absences information
    last modified, ahmedaa@mit.edu, December 29 1999
    added vacation_type selection

    @param vacation_id:integer 
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    
    @cvs-id edit.tcl,v 1.3.2.9 2000/09/22 01:38:24 kevin Exp
} {
    vacation_id:naturalnum,notnull
    { return_url "" }
}


set my_user_id [ad_maybe_redirect_for_registration]


set selection [ns_set create] 
if {[catch {db_1row vacation_select "
    select uv.start_date, uv.end_date, uv.description, uv.contact_info, uv.user_id, 
           nvl(uv.receive_email_p, 't') as receive_email_p, uv.vacation_type,
           u.first_names || ' ' || u.last_name as user_name
    from user_vacations uv, users u
    where uv.vacation_id = :vacation_id
      and uv.user_id=u.user_id"} errmsg]} {
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

# Only the user whose vacation this is, or an administrator, can delete the vacation.
if { $user_id == $my_user_id || [im_is_user_site_wide_or_intranet_admin $my_user_id] } {
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

# show mini calendars for up to 4 months from now

db_1row future_months_julian_dates \
	"select trunc(add_months(sysdate,1)) as next_month_julian_date_1,
                trunc(add_months(sysdate,2)) as next_month_julian_date_2,
                trunc(add_months(sysdate,3)) as next_month_julian_date_3
           from dual"

set page_title "Edit absence for $user_name ([util_AnsiDatetoPrettyDate $start_date])"
set context_bar [ad_context_bar_ws [list ./ "Work absences"] "Edit"]

set page_body "
[im_header]

<table><tr><td valign=top align=left>
<!-- This column contains the form to enter information about the work absence -->

<form method=POST action=edit-2>
[export_form_vars vacation_id return_url]" 

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
[im_employee_select_optionlist $user_id]
</select>
</td>
</tr>

<tr><th valign=top align=right>Description</th>
<td><textarea name=description cols=40 rows=8 wrap=soft>[ns_quotehtml $description]</textarea></td></tr>

<tr><th valign=top align=right>Emergency contact information</th>
<td><textarea name=contact_info cols=40 rows=8 wrap=soft>[ns_quotehtml $contact_info]</textarea></td></tr>

<tr><th valign=top align=right>Receive email?</th>
<td>Yes <input type=radio name=receive_email_p value=\"t\" [ad_decode $receive_email_p "t" "checked" ""]>
    No <input type=radio name=receive_email_p value=\"f\" [ad_decode $receive_email_p "f" "checked" ""]>

</td></tr>

</table>
<p>
<center><input type=submit value=\"Edit absence\"></center>

[ad_decode $can_delete_p 1 "
<ul>
  <li> <a href=delete?[export_url_vars vacation_id return_url]>Delete this absence</a>
</ul>" ""]

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



