#/admin/users/index.tcl

ad_page_contract {
    by a bunch of folks including philg@mit.edu and teadams@arsdigita.com
    modified by philg on October 30, 1999 to cache the page
    (sequentially scanning through users and such was slowing it down)
    
    modified by aure@caltech.edu on February 4, 2000 to make the page more
    user friendly
    
    we define this procedure here in the file because we don't care if
    it gets reparsed; it is RDBMS load that was slowing stuff down.  We also  
    want programmers to have an easy way to edit this page.

    @author Multiple
    @creation-date ?
    @cvs-id index.tcl,v 3.9.2.3.4.5 2000/09/22 01:36:18 kevin Exp

} {}

ad_proc next_color {bg_color} {
    if {$bg_color=="#eeeeee"} {
	set bg_color "#f5f5f5"
    } else {
	set bg_color "#eeeeee"
    }
    uplevel "set bgcolor $bg_color"
    return $bg_color
}

ad_proc ad_admin_users_index_dot_tcl_whole_page {} {

    set bgcolor "#f5f5f5"

    set whole_page ""
    # sadly the rest of the file isn't properly indented
    # because I was too lazy.

append whole_page "[ad_admin_header "Users"]

<h2>Users</h2>

[ad_admin_context_bar "Users"]

<hr>

<ul>
<li>total users:  
"

db_foreach users_n_users "select 
   count(*) as n_users, 
   sum(decode(user_state,'deleted',1,0)) as n_deleted_users, 
   max(registration_date) as last_registration
from users
where email not in ('anonymous', 'system')" {
    if { $n_users < 200 } {
	set complete_users "<a href=\"action-choose?special=all\">$n_users</a>"
    } else {
	set complete_users [util_commify_number $n_users]
    }
}

append whole_page "$complete_users ($n_deleted_users deleted).  Last registration on [util_AnsiDatetoPrettyDate $last_registration] (<a href=\"registration-history\">history</a>).

"

if [mv_enabled_p] {
    append whole_page "<li><a href=\"action-choose?expensive=1&include_accumulated_charges_p=1\">expensive users</a>
"
}

set state_list ""

db_foreach user_states "select count(user_state) 
as num_in_state, user_state
from users 
group by user_state" {
    set user_state_num($user_state) [util_commify_number $num_in_state]
}

if {[ad_parameter RegistrationRequiresApprovalP "" 0] && [info exists user_state_num(need_admin_approv)]} {
    lappend state_list "<a href=action-choose?user_state=need_admin_approv>need_admin_approv</a> ($user_state_num(need_admin_approv))"
}

if {[ad_parameter RegistrationRequiresApprovalP "" 0] && [ad_parameter RegistrationRequiresEmailVerificationP "" 0] && [info exists user_state_num(need_email_verification_and_admin_approv)]} {
    lappend state_list "<a href=action-choose?user_state=need_email_verification_and_admin_approv>need_email_verification_and_admin_approv</a>  ($user_state_num(need_email_verification_and_admin_approv))"
}

if {[ad_parameter RegistrationRequiresEmailVerificationP "" 0] && [info exists user_state_num(need_email_verification)]} {
    lappend state_list "<a href=action-choose?user_state=need_email_verification>need_email_verification</a> ($user_state_num(need_email_verification))"
}

if [info exists user_state_num(authorized)] {
    lappend state_list "<a href=action-choose?user_state=authorized>authorized</a> ($user_state_num(authorized))"
}

if [info exists user_state_num(banned)] {
    lappend state_list "<a href=action-choose?user_state=banned>banned</a>  ($user_state_num(banned))"
}

if [info exists user_state_num(deleted)] {
    lappend state_list "<a href=action-choose?user_state=deleted>deleted</a>  ($user_state_num(deleted))"
}

append whole_page "  
<li>Users in state: [join $state_list " | "]
<p>
"

db_1row user_sessions "
select 
  sum(session_count) as total_sessions, 
  sum(repeat_count) as total_repeats
from session_statistics"

if [empty_string_p $total_sessions] {
    set total_sessions 0
}
if [empty_string_p $total_repeats] {
    set total_repeats 0
}

set spam_count [db_string spam_count "
select sum(n_sent) from spam_history"]
if [empty_string_p $spam_count] {
    set spam_count 0
} 

append whole_page "

<p>

<li>registered sessions:  <a href=\"sessions-registered-summary\">by days since last login</a>
<li>total sessions (includes unregistered users):  
<a href=\"session-history\">[util_commify_number $total_sessions] ([util_commify_number $total_repeats] repeats)</a>

<FORM METHOD=get ACTION=search>
<input type=hidden name=target value=\"one\">
<input type=hidden name=only_authorized_p value=\"0\">
<li>Quick search: <input type=text size=15 name=keyword>
</FORM>

<li><a href=\"user-add\">Add a user</a>

<p>

<li><a href=\"/admin/spam/\">Review spam history</a> 
([util_commify_number $spam_count] sent) 

<p>

<form method=post action=action-choose>
<li>Previously defined user class: <select name=user_class_id>
[db_html_select_value_options user_class_select_options "select user_class_id, name from user_classes"]
</select>
<input type=submit name=submit value=\"Go\">
</form>
</ul>
<h3>Pick a user class</h3>
<ul>
<table cellspacing=1 border=0>
<tr bgcolor=[next_color $bgcolor]>
<form method=post action=action-choose>
<td align=right>Customer state:</td>
<td><select name=crm_state>
<option></option>
[db_html_select_value_options crm_states_select_options "select state_name, state_name || ' - ' || count(user_id) || ' users'
from crm_states, users
where crm_states.state_name = users.crm_state
group by state_name
order by lower(state_name)"]

</select>
</td>
</tr>
<tr bgcolor=[next_color $bgcolor]>
<td align=right>Interest:</td>
<td> <select name=category_id>
<option></option>
[db_html_select_value_options user_interest_categories "select c.category_id, c.category || ' - ' || count(user_id) || ' users'
from users_interests ui, categories c
where ui.category_id = c.category_id
group by c.category, c.category_id
order by lower(c.category)"]
</select></td></tr>"

if [ad_parameter InternationalP] {
    # there are some international users 
    append whole_page "<tr bgcolor=[next_color $bgcolor]><td align=right>Country:</td><td> 
<select name=country_code>
<option></option>
[db_html_select_value_options countries_select_options "select c.iso, c.country_name || ' - ' || count(user_id) || ' users'
from users_contact uc, country_codes c
where uc.ha_country_code = c.iso
group by c.country_name, c.iso
order by lower(c.country_name)"]
</select></td></tr>
"
}

if [ad_parameter SomeAmericanReadersP] {
    append whole_page "<tr bgcolor=[next_color $bgcolor]><td align=right>State:</td><td>
<select name=usps_abbrev>
<option></option>
[db_html_select_value_options states_select_options "select s.usps_abbrev, s.state_name || ' - ' || count(user_id) || ' users'
from users_contact uc, states s
where uc.ha_state = s.usps_abbrev
and (uc.ha_country_code is null or uc.ha_country_code = 'us')
group by s.state_name, s.usps_abbrev
order by lower(s.state_name)"]
</select></td></tr>"
}

append whole_page "
<tr bgcolor=[next_color $bgcolor]>
<td align=right>Group:</td>
<td><select name=group_id>
<option></option>
[db_html_select_value_options user_groups_select_options "select user_groups.group_id, group_name || ' - ' || count(user_id) || ' users'
from user_groups, user_group_map
where user_groups.group_id = user_group_map.group_id
group by user_groups.group_id, group_name
order by lower(group_name)"]
</select>
</td>
</tr>
<tr bgcolor=[next_color $bgcolor]>
<td align=right>Sex:</td>
<td><select name=sex>
<option></option>
<option value=\"m\">Male</option>
<option value=\"f\">Female</option>
</select>
</td>
</tr>
<tr bgcolor=[next_color $bgcolor]>
<td align=right>Age:</td>
<td>
<table border=0 cellpadding=2 cellspacing=0>
<tr><td align=right>
over</td><td> <input type=text size=3 name=age_above_years> years 
</td></tr> 
<tr><td align=right>
under</td><td> <input type=text size=3 name=age_below_years> years
</td></tr></table>

</td>
</tr>
<tr bgcolor=[next_color $bgcolor]>
<td align=right>Registration date:</td>
<td>
<table border=0 cellpadding=2 cellspacing=0>
<tr><td align=right>
over</td><td> <input type=text size=3 name=registration_before_days> days ago
</td></tr> 
<tr><td align=right>
under</td><td> <input type=text size=3 name=registration_after_days> days ago
</td></tr></table>
</td>
</tr>
<tr bgcolor=[next_color $bgcolor]>
<td align=right>Last login:</td>
<td>
<table border=0 cellpadding=2 cellspacing=0>
<tr><td align=right>
over</td><td> <input type=text size=3 name=last_login_before_days> days ago
</td></tr> 
<tr><td align=right>
under</td><td> <input type=text size=3 name=last_login_after_days> days ago
</td></tr></table>
</td>
</tr>
<tr bgcolor=[next_color $bgcolor]>
<td align=right>Number of visits:</td>
<td>
<table border=0 cellpadding=2 cellspacing=0>
<tr><td align=right>
less than</td><td> <input type=text size=3 name=number_visits_below>
</td></tr>
<tr><td align=right>
more than </td><td><input type=text size=3 name=number_visits_above>
</td></tr></table>
</td>
</tr>
<tr bgcolor=[next_color $bgcolor]>
<td align=right>Last name starts with:</td>
<td>
<input type=text name=last_name_starts_with>
</td>
</tr>
<tr bgcolor=[next_color $bgcolor]>
<td align=right>Email starts with:</td>
<td> <input type=text name=email_starts_with>
</td>
</tr>
<tr bgcolor=[next_color $bgcolor]>
<td>&nbsp;</td>
<td>
Join the above criteria by <input type=radio name=combine_method value=\"and\" checked> and <input type=radio name=combine_method value=\"or\"> or 
</td>
</tr>
<tr>
<td colspan=2 align=center>
<input type=submit name=Submit value=Submit>
</td>
</tr>
</form>
</table>
</ul>
</ul>"

if {[ad_parameter AllowAdminSQLQueries "" 0] == 1} {
    append whole_page "<blockquote>
<h3>Select by SQL</h3>
<form action=action-choose method=post>
select users.* <br>
<textarea cols=40 rows=4 name=sql_post_select></textarea><br>
<i>example: from users where user_id < 1000</i>
<center>
<input type=submit name=submit value=Submit>
</center>
</form>
</blockquote>"
}

append whole_page "

[ad_style_bodynote "For fluidity of administrations, this page is cached in RAM for 15 minutes.  Thus the numbers you see above may be up to 15 minutes out of date."]

[ad_admin_footer]"
}

doc_return  200 text/html [util_memoize "ad_admin_users_index_dot_tcl_whole_page" 900] 


