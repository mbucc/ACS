# $Id: index.tcl,v 3.3.2.4 2000/03/17 07:26:01 mbryzek Exp $
#
# File: /www/intranet/employees/admin/index.tcl
# Author: mbryzek@arsdigita.com, Jan 2000
# Adminstrative view of all employees


set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables 0
# optional: status_id

set db_list [ns_db gethandle main 2]
set db [lindex $db_list 0]
set db2 [lindex $db_list 1]

set view_types "<b>Admin View</b> | <a href=../org-chart.tcl>Org Chart</a> | <a href=../index.tcl>Standard View</a>"

set page_title "Employees"
set context_bar [ad_context_bar [list "/" Home] [list ../../index.tcl "Intranet"] $page_title]

ReturnHeaders
ns_write "
[ad_partner_header]

<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr><td align=right>$view_types</td></tr>
</table>


"

set missing_html "<em>missing</em>"

set selection [ns_db select $db \
	"select users.user_id , nvl(info.salary, 0) as salary, users.last_name || ', ' || users.first_names as name,
                info.supervisor_id, info.years_experience as n_years_experience, info.salary_period, info.referred_by, 
                to_char(info.start_date,'Mon DD, YYYY') as start_date_pretty,
                decode(info.project_lead_p, 't', 'Yes', 'No') as project_lead,
                decode(info.team_leader_p, 't', 'Yes', 'No') as team_lead,
                decode(supervisor_id, NULL, '$missing_html', s.first_names || ' ' || s.last_name) as supervisor_name,
                decode(info.referred_by, NULL, '<em>nobody</em>', r.first_names || ' ' || r.last_name) as referral_name
           from users_active users, im_employee_info info, user_group_map ugm, users s, users r
          where users.user_id = ugm.user_id
            and ugm.group_id = [im_employee_group_id]
            and users.user_id = info.user_id(+) 
            and info.referred_by = r.user_id(+)
            and info.supervisor_id = s.user_id(+) 
       order by upper(name)"]


set ctr 0
set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top>[ad_partner_default_font "size=-1"] <a href=view.tcl?[export_url_vars user_id]>$name</a> </font></td>
  <td valign=top>[ad_partner_default_font "size=-1"]  
"
    append results "
Supervisor: <a href=update-supervisor.tcl?[export_url_vars user_id]>$supervisor_name</a>
<br>Experience: "    
    if { [empty_string_p $n_years_experience] } {
        append results $missing_html
    } else {
        append results "$n_years_experience [util_decode $n_years_experience 1 year years]"
    }
    append results "<br>Referred by: $referral_name"
    append results "\n</font></td>\n"

    if { ![catch {set new_time [database_to_tcl_string $db2 \
	    "select percentage_time 
               from im_employee_percentage_time 
              where user_id = $user_id 
                and start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')"]} errmsg] } {
	set percentage $new_time
    } else {
	set percentage "x"
    }

    append results "
  <td valign=top>[ad_partner_default_font "size=-1"]<center> <a href=history.tcl?[export_url_vars user_id]>$percentage</a> </center></font></td>
  <td valign=top>[ad_partner_default_font "size=-1"]<center> [util_decode $start_date_pretty "" "&nbsp;" $start_date_pretty] </center></font></td>
  <td valign=top>[ad_partner_default_font "size=-1"]<center> $team_lead </center></font></td>
  <td valign=top>[ad_partner_default_font "size=-1"]<center> $project_lead </center></font></td>
</tr>
"
    incr ctr
}

set intranet_admin_group_id [database_to_tcl_string $db \
	"select group_id from user_groups where group_type='administration' and short_name='[ad_parameter IntranetGroupType intranet intranet]'"]

ns_db releasehandle $db
ns_db releasehandle $db2


if { [empty_string_p $results] } {
    set results "<ul><li><b> There are currently no employees</b></ul>\n"
} else {
    set results "
<br>
<table width=100% cellpadding=1 cellspacing=2 border=0>
<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
  <th valign=top>[ad_partner_default_font "size=-1"]Name</font></th>
  <th valign=top>[ad_partner_default_font "size=-1"]Details</font></th>
  <th valign=top>[ad_partner_default_font "size=-1"]Current<br>Percentage</font></th>
  <th valign=top>[ad_partner_default_font "size=-1"]Start Date</font></th>
  <th valign=top>[ad_partner_default_font "size=-1"]Team Leader?</font></th>
  <th valign=top>[ad_partner_default_font "size=-1"]Project Leader?</font></th>
</tr>
$results
</table>
"
}


ns_write "
$results
<p> 
<ul>
  <li> <a href=referral.tcl>Referral Summary Page</a>
  <li> <a href=/groups/member-add.tcl?role=member&return_url=[ad_partner_url_with_query]&group_id=[im_employee_group_id]>Add an employee</a>
  <li> <a href=/groups/member-add.tcl?role=administrator&return_url=[ad_partner_url_with_query]&group_id=$intranet_admin_group_id>Add an Intranet administrator</a>
</ul>

[ad_partner_footer]
"
