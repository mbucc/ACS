# /www/intranet/employees/admin/index.tcl

ad_page_contract {
    
    Adminstrative view of all employees
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Fri May 26 18:03:28 2000
    @cvs-id index.tcl,v 3.30.2.7 2000/09/22 01:38:34 kevin Exp
    @param status_id Optional The status ID
    @param group_id Optional The group ID to examine
    @param viewing_group_id Optional The group to view
    @param start_idx Optional The start index
    @param how_many Optional How many to view
    @param letter Optional The letter to search with
} {
    { status_id "" }
    { group_id "" }
    { viewing_group_id "" }
    { start_idx "1" }
    { how_many "" }
    { letter "scroll" }
}



# Allow people to call this page with "group_id" - transfer it to 
# viewing_group_id to save the variable
if { [empty_string_p $viewing_group_id] && ![empty_string_p $group_id] } {
    set viewing_group_id $group_id
}

set default_order_by "order by upper(name)" 

# Set up boundaries to limit the amount of rows we display
if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter NumberResultsPerPage intranet 50]
}
set end_idx [expr $start_idx + $how_many]

set user_id [ad_maybe_redirect_for_registration]

set view_types "<b>Admin View</b> | <a href=../org-chart>Org Chart</a> | <a href=../index?[export_ns_set_vars url]>Standard View</a>"

set page_title "Employees"
set context_bar [ad_context_bar_ws $page_title]

set team_list [list "0" "All"]

db_foreach select_teams "select group_id, group_name
           from user_groups 
          where parent_group_id = [im_team_group_id]" {
    lappend team_list $group_id $group_name
}

set team_slider [im_slider viewing_group_id $team_list $viewing_group_id "start_idx group_id"]

set office_list [list "0" "All"]
db_foreach get_offices  	"select group_id, group_name
           from user_groups 
          where parent_group_id = [im_office_group_id]" {
    lappend office_list $group_id $group_name
}

set office_slider [im_slider viewing_group_id $office_list $viewing_group_id "start_idx group_id"]

set criteria [list]

if { ![empty_string_p $viewing_group_id] && $viewing_group_id>0 } {
    set group_name [db_string get_group_name \
	    "select group_name from user_groups where group_id=:viewing_group_id"]
    append page_title " in group \"$group_name\""
    lappend criteria "ad_group_member_p(u.user_id, :viewing_group_id) = 't'"
}
if { ![empty_string_p $letter] && [string compare $letter "all"] != 0 && [string compare $letter "scroll"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(u.last_name)=upper(:letter)"
}

if { [llength $criteria] > 0 } {
    set where_clause [join $criteria "\n         and "]
} else {
    set where_clause "1=1"
}

set missing_html "<em>missing</em>"

set sql "select u.user_id , nvl(u.salary, 0) as salary, u.last_name || ', ' || u.first_names as name,
                u.supervisor_id, u.years_experience as n_years_experience, u.salary_period, u.referred_by, 
                to_char(u.start_date,'Mon DD, YYYY') as start_date_pretty, 
                decode(u.project_lead_p, 't', 'Yes', 'No') as project_lead,
                decode(u.team_leader_p, 't', 'Yes', 'No') as team_lead,
                decode(supervisor_id, NULL, '$missing_html', s.first_names || ' ' || s.last_name) as supervisor_name,
                decode(u.referred_by, NULL, '<em>nobody</em>', r.first_names || ' ' || r.last_name) as referral_name
           from im_employees_active u, users s, users r
          where u.referred_by = r.user_id(+)
            and u.supervisor_id = s.user_id(+) and $where_clause  $default_order_by"

if { [string compare $letter "all"] == 0 } {
    
    set daquery $sql
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1

} else {

    set limited_query [im_select_row_range $sql $start_idx $end_idx]

    set total_in_limited [db_string get_total_in_limited \
	    "select count(*) from im_employees_active u where $where_clause"]
    
    
    set daquery $limited_query
}

set ctr 0
set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""
db_foreach get_stuff $daquery {
    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top><font size=-1> <a href=view?[export_url_vars user_id]>$name</a> </font></td>
  <td valign=top><font size=-1>  
"
    append results "
Supervisor: <a href=update-supervisor?[export_url_vars user_id]>$supervisor_name</a>
<br>Experience: "    
    if { [empty_string_p $n_years_experience] } {
        append results $missing_html
    } else {
        append results "$n_years_experience [util_decode $n_years_experience 1 year years]"
    }
    append results "<br>Referred by: $referral_name"
    append results "\n</font></td>\n"

    if { ![catch {set new_time [db_string get_new_time \
	    "select percentage_time 
               from im_employee_percentage_time 
              where user_id = $user_id 
                and start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')"]} errmsg] } {
	set percentage $new_time
    } else {
	set percentage "x"
    }

    append results "
  <td valign=top><font size=-1><center> <a href=history?[export_url_vars user_id]>$percentage</a> </center></font></td>
  <td valign=top><font size=-1><center> [util_decode $start_date_pretty "" "&nbsp;" $start_date_pretty] </center></font></td>
  </tr>
"
    incr ctr
    if { $how_many > 0 && $ctr >= $how_many } {
	break
    }
}

if { $ctr == $how_many && $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page 
    set next_start_idx [expr $end_idx + 1]
    set next_page "<a href=index?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]>Next Page</a>"
} else {
    set next_page ""
}

if { $start_idx > 1 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 1 } {
	set previous_start_idx 1
    }
    set previous_page "<a href=index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]>Previous Page</a>"
} else {
    set previous_page ""
}

set navbar [im_default_nav_header $previous_page $next_page "[im_url_stub]/employees/search.tcl" "[im_url_stub]/employees/admin/view.tcl" "Search"]

set intranet_admin_group_id [db_string get_inet_gid \
	"select group_id from user_groups where group_type='administration' and short_name='[ad_parameter IntranetGroupType intranet intranet]'"]

db_release_unused_handles

if { [empty_string_p $results] } {
    set results "<ul><li><b> There are currently no employees matching the selected criteria</b></ul>\n"
} else {
    set results "
<br>
<table width=100% cellpadding=1 cellspacing=2 border=0>
<tr>
  <td align=center valign=top colspan=4><font size=-1>
    [im_groups_alpha_bar [im_project_group_id] $letter "start_idx"]
  </font></td>
</tr>
<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
  <th valign=top><font size=-1>Name</font></th>
  <th valign=top><font size=-1>Details</font></th>
  <th valign=top><font size=-1>Current<br>Percentage</font></th>
  <th valign=top><font size=-1>Start Date</font></th>
  </tr>
$results
<tr>
  <td align=center colspan=4>[im_maybe_insert_link $previous_page $next_page]</td>
</tr>
</table>
"
}

append page_body "
<table width=100% cellpadding=0 cellspacing=2 border=0>
  <tr bgcolor=eeeeee>
    <th>Office</th>
    <th>Team</th>
    <th>$view_types</th>
  </tr>
  <tr>
    <td align=center valign=top><font size=-1>$office_slider</font></td>
    <td align=center valign=top><font size=-1>$team_slider</font></td>
    <td align=center valign=top><font size=-1>$navbar</font></td>
  </tr>
</table>

$results
<p> 
<ul>
  <li> <a href=referral>Referral Summary Page</a>
  <li> <a href=pipeline-list>View employee pipeline</a>
  <li> <a href=[im_url_stub]/member-add?role=member&return_url=/intranet/employees/admin/view&group_id=[im_employee_group_id]>Add an employee</a>
"

if ![empty_string_p $viewing_group_id] {
    append page_body "<li><a href=bulk-edit?group_id=$viewing_group_id>Bulk edit this group</a>"
}

append page_body "</ul>
"

doc_return  200 text/html [im_return_template]
