# /www/intranet/users/info-update.tcl

ad_page_contract {
    Purpose: Updates a user's intranet information

    @param from

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id info-update.tcl,v 3.11.2.7 2000/09/22 01:38:51 kevin Exp
} {
    { from "" }
}

set user_id [ad_maybe_redirect_for_registration]

db_1row get_all_from_user "
select 
  first_names, 
  last_name, 
  email, 
  url, 
  bio,
  aim_screen_name, 
  info.*,
  icq_number, 
  users_contact.current_information,
  users_contact.note, 
  home_phone, 
  work_phone, 
  cell_phone, 
  ha_line1, 
  ha_line2, 
  ha_city, 
  ha_state, 
  ha_postal_code,
  featured_employee_blurb,
  featured_employee_blurb_html_p,
  recruiting_blurb,
  recruiting_blurb_html_p
from users, users_contact, im_employee_info info
where users.user_id = users_contact.user_id(+)
and users.user_id = info.user_id(+)
and users.user_id = :user_id" 


set page_title "$first_names $last_name"
set context_bar [ad_context_bar_ws [list "./" "Users"] [list view.tcl?[export_url_vars user_id] "One user"] "Update info"]

set page_body "

<form method=post action=info-update-2>
[export_form_vars return_url]

<table>

<tr>
 <th>name:</th>
 <td><input type=text name=dp.users.first_names size=20 maxlength=100 [export_form_value first_names]> 
     <input type=text name=dp.users.last_name size=25 maxlength=100 [export_form_value last_name]>
 </td>
</tr>
<tr>
 <th>email address:</th>
 <td><input type=text name=dp.users.email.email size=30 maxlength=100 [export_form_value email]></td>
</tr>
<tr>
 <th>Personal URL:</th>
 <td><input type=text name=dp.users.url size=50  maxlength=200 [export_form_value url]></td>
</tr>
<tr>
 <th>AIM name:</th>
 <td><input type=text name=dp.users_contact.aim_screen_name size=20  maxlength=50 [export_form_value aim_screen_name]></td>
</tr>
<tr>
 <th>ICQ number:</th>
 <td><input type=text name=dp.users_contact.icq_number size=20 maxlength=50 [export_form_value icq_number]></td>
</tr>

<tr>
 <th>Home phone:</th>
 <td><input type=text name=dp.users_contact.home_phone size=20 maxlength=100 [export_form_value home_phone]></td>
</tr>

<tr>
 <th>Work phone:</th>
 <td><input type=text name=dp.users_contact.work_phone size=20 maxlength=100 [export_form_value work_phone]></td>
</tr>

<tr>
 <th>Cell phone:</th>
 <td><input type=text name=dp.users_contact.cell_phone size=20 maxlength=100 [export_form_value cell_phone]></td>
</tr>

<tr><td colspan=2></td></tr>

<tr>
 <th valign=top>Home address:</th>
 <td>
    <table>
     <tr>
        <th align=right>Street:</th>
        <td><INPUT name=dp.users_contact.ha_line1 maxlength=80 [export_form_value ha_line1] size=30></td>
     </tr>
     <tr>
        <th align=right>&nbsp;</th>
        <td><INPUT name=dp.users_contact.ha_line2 maxlength=80 [export_form_value ha_line2] size=30></td>
     </tr>
     <tr>
        <th align=right>City:</th>
        <td><INPUT name=dp.users_contact.ha_city maxlength=80 [export_form_value ha_city] size=20></td>
     </tr>
     <tr>
        <th align=right>State:</th>
        <td>[state_widget [value_if_exists ha_state] dp.users_contact.ha_state]</td>
     </tr>
     <tr>
        <th align=right>Zip:</th>
        <td><INPUT name=dp.users_contact.ha_postal_code maxlength=80 [export_form_value ha_postal_code] size=10></td>
     </tr>
    </table>
 </td>
</tr>

<tr><td colspan=2></td></tr>

<tr>
 <th>List your degrees with the school names:</TH>
<td><textarea name=dp.im_employee_info.educational_history COLS=50 ROWS=6 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists educational_history]]</textarea></td>
</tr>

<tr><td colspan=2></td></tr>

<tr>
 <th>Last degree you completed?</TH>
<td>
<select name=dp.im_employee_info.last_degree_completed>
[html_select_options {"" "High School" "Bachelors" "Master" "PhD"} [value_if_exists last_degree_completed]]
</select>
</td>
</tr>

<tr><td colspan=2></td></tr>

<tr>
 <TD ALIGN=CENTER WIDTH=200><B>Biography:</B><BR>
<FONT SIZE=-1>
</FONT>
</td>
 <td>
<textarea name=dp.users.bio cols=50 rows=4 wrap=soft>[philg_quote_double_quotes [value_if_exists bio]]</textarea></td>
</tr>

<tr><td colspan=2></td></tr>

<tr><td colspan=2></td></tr>

<tr>
 <TD ALIGN=CENTER WIDTH=200><B>Special skills:</B><BR>
<FONT SIZE=-1>(when your coworkers need to find
someone who can do <EM>X</EM>)
</FONT>
</td>
 <td>
<textarea name=dp.im_employee_info.skills cols=50 rows=4 wrap=soft>[philg_quote_double_quotes [value_if_exists skills]]</textarea></td>
</tr>

<tr><td colspan=2></td></tr>

<tr>
 <th>Years experience in this field?</TH>
<td>
<select name=dp.im_employee_info.years_experience.integer>
[html_select_options {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30} $years_experience ]
</select>
</td>
</tr>

<tr><td colspan=2></td></tr>

<tr>
 <TD ALIGN=CENTER WIDTH=200><B>Resume:</B>
</td>
 <td>
<textarea name=dp.im_employee_info.resume.clob cols=50 rows=4 wrap=soft>[philg_quote_double_quotes [value_if_exists resume]]</textarea>
<p>

The above resume is:
<select name=dp.im_employee_info.resume_html_p>
[html_select_value_options {{"t" "HTML"} {"f" "Text"}}  [value_if_exists resume_html_p]]
</select>
</td>
</tr>

<tr><td colspan=2></td></tr>

<tr>
 <th>Other notes:<td><textarea name=dp.users_contact.note cols=50 rows=4 wrap=soft>[philg_quote_double_quotes [value_if_exists note]]</textarea></td>
</tr>

<tr><td colspan=2></td></tr>

<tr>
 <TD ALIGN=CENTER WIDTH=200><B>Featured Employee Blurb:</B>
</td>
 <td>
<textarea name=dp.im_employee_info.featured_employee_blurb.clob cols=50 rows=6 wrap=soft>[philg_quote_double_quotes [value_if_exists featured_employee_blurb]]</textarea>
<p>

The above blurb is:
<select name=dp.im_employee_info.featured_employee_blurb_html_p>
[html_select_value_options {{"t" "HTML"} {"f" "Text"}}  [value_if_exists featured_employee_blurb_html_p]]
</select>
</td>
</tr>

<tr>
 <TD ALIGN=CENTER WIDTH=200><B>Recruiting Blurb:</B>
</td>
 <td>
<textarea name=dp.im_employee_info.recruiting_blurb.clob cols=50 rows=6 wrap=soft>[philg_quote_double_quotes [value_if_exists recruiting_blurb]]</textarea>
<p>

The above blurb is:
<select name=dp.im_employee_info.recruiting_blurb_html_p>
[html_select_value_options {{"t" "HTML"} {"f" "Text"}}  [value_if_exists recruiting_blurb_html_p]]
</select>
</td>
</tr>

</table>

<br>
<br>
<center>
<input type=submit value=\"Update\">
</center>
</form>
"

doc_return  200 text/html [im_return_template]
