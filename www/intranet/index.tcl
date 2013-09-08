# /www/intranet/index.tcl

ad_page_contract {
    Purpose: top level, portal-like page, for employees, for the intranet

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id index.tcl,v 3.36.2.15 2000/10/27 09:24:55 tony Exp
} {
}

set special_index_page [ad_parameter SpecialIndexPage intranet]

if ![empty_string_p $special_index_page] {
    set full_filename "[ns_info pageroot]$special_index_page"
    if [file exists $full_filename] {
	ad_returnredirect  $special_index_page
	return
    }
}

# user_id already validated by /intranet filters
set user_id [ad_get_user_id]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]


if { ![db_0or1row user_name \
	"select first_names || ' ' || last_name as full_name 
           from users 
          where user_id=:user_id"] } {
    ad_return_error "User doesn't exist" "We're sorry, but we can't find you in our database. You can <a href=/register/logout>logout</a> and try logging in again."
    return
}

set portrait_exists_p [db_0or1row portrait_info "
   select portrait_id
     from general_portraits
    where on_what_id = :user_id
      and upper(on_which_table) = 'USERS'
      and approved_p = 't'
"]
set page_title "${full_name}'s workspace at [ad_parameter IntranetName intranet Intranet]"
set context_bar [ad_context_bar [list / Home] "Your workspace"]
set page_focus "employee_search.keywords"

set sql "select ug.group_name, ug.group_id
           from user_groups ug, im_projects p
          where ad_group_member_p ( :user_id, ug.group_id ) = 't'
            and ug.group_id=p.group_id
            and p.project_status_id in (select project_status_id
                                          from im_project_status 
                                         where project_status='Open' 
                                            or project_status='Future' )
          order by lower(group_name)"

db_foreach groups_user_belongs_to $sql {
    append projects "  <li> <a href=projects/view?[export_url_vars group_id]>$group_name</a>\n"
} if_no_rows {
    set projects "<p>"
}

append projects "  <li> <a href=projects/index?mine_p=f>Browse projects</a>\n"

set sql "select ug.group_name, ug.group_id
           from user_groups ug, im_customers c
          where ad_group_member_p ( :user_id, ug.group_id ) = 't'
            and ug.group_id=c.group_id
            and c.customer_status_id in (select customer_status_id 
                                          from im_customer_status 
                                         where customer_status in ('Current','Inquiries','Creating Bid','Bid out'))
          order by lower(group_name)"

db_foreach customers_user_belongs_to $sql  {
    append customers "  <li> <a href=customers/view?[export_url_vars group_id]>$group_name</a>\n"
} if_no_rows {
    append customers "<p>"
}
append customers "  <li> <a href=customers/index?view_type=all>Browse customers</a>\n"

if { [ad_parameter TrackHours intranet 0] } {
    set on_which_table "im_projects"
    set num_hours [hours_sum_for_user $user_id $on_which_table "" 7]
    if { $num_hours == 0 } {
	append hours "<b>You haven't logged your hours in the last week. Please <a href=hours/index?[export_url_vars on_which_table]>log them now</a></b>\n"
    } else {
	append hours "You logged $num_hours [util_decode $num_hours 1 hour hours] in the last 7 days."
    }
    append hours "
<ul>
  <li><a href=hours/projects?[export_url_vars on_which_table user_id]>View your hours on all projects</a>
  <li><a href=hours/total?[export_url_vars on_which_table]>View time spent on all projects by everyone</a>
  <li><a href=hours/projects?[export_url_vars on_which_table]>View the hours logged by someone else</a>
  <li><a href=hours/index?[export_url_vars on_which_table]>Log hours</a>
</ul>
" 
} else {
    set hours ""
}

set return_url [im_url_with_query]
set since_when [db_string sysdate_from_dual "select sysdate - 30 from dual"]
set news [news_new_stuff $since_when 0 "web_display" 1 0 [im_employee_group_id]]
set news_dir [im_groups_url -short_name [ad_parameter EmployeeGroupShortName intranet employee] -section news]

if { [ad_parameter ApprovalPolicy news] == "open"} {
    append news "\n<li><a href=\"$news_dir/post-new?[export_url_vars return_url]\">post an item</a>\n"
} elseif { [ad_parameter ApprovalPolicy news] == "wait"} {
    append news "\n<li><a href=\"$news_dir/post-new?[export_url_vars return_url]\">suggest an item</a>\n"
}
append news " | <a href=$news_dir/index?archive_p=1>archives</a>\n"


set task_blurb "<ul>\n"

set sql "select tb.task_name, tb.task_id, c.category as time,
                c.profiling_weight as weight
           from categories c, intranet_task_board tb
          where tb.expiration_date > sysdate
            and c.category_id = tb.time_id
          order by time desc"

set last_time ""
set task_blurb_list ""

db_foreach list_all_tasks $sql {
    if {$last_time != $time } {
        append task_blurb "[join $task_blurb_list " | "] <li><b>$time</b>: "
        set task_blurb_list ""
    }
    set last_time $time
    lappend task_blurb_list " <a href=task-board/one?[export_url_vars task_id]>$task_name</a>  "
}

append task_blurb "[join $task_blurb_list " | "]
<p><li><a href=task-board/ae>Post a task</a></ul>"

if [apm_package_enabled_p "calendar"] {
    set monthly_calendar_link "<li><a href=\"/calendar/?view=month&group_id=[im_employee_group_id]\">Calendar (monthly view with vacations!)</a>"
} else {
    set monthly_calendar_link "<li><a href=/calendar/monthly>Calendar (monthly view with vacations!)</a>"
}

set left_column "

[im_late_project_reports  $user_id]
<P><em><a href=\"/news/\">[ad_parameter SystemName] News</a></em>
<ul>
  $news
</ul>

<form method=get name=employee_search action=employees/search>
<table width=100%>
<tr><td valign=top>
<ul>
  <li><a href=employees/>Employees</A> (<a href=employees/org-chart>org chart</a>)
  <br><font size=-1>
      Search: <input type=text name=keywords size=20>
  <br><input name=search_type type=submit value=\"Search\"> 
      <input name=search_type type=submit value=\"Feeling Lucky\"></font></form>
 
  <p>
  <li><a href=offices/>Offices</a>
  <li><a href=facilities/>Facilities</a>
  <li><a href=partners/>Partners</a>
  <li><a href=procedures/>Procedures</A>
  <p>
  <!-- <li><a href=/address-book/index?scope=public>Address book: [ad_parameter IntranetName intranet]</a> -->
  <li><a href=/address-book/>Address Book: Private</a>
  $monthly_calendar_link
  <li><a href=/wp>WimpyPoint</a>
  <li><a href=/directory>Directory</a>
  <p>
  <li><a href=/bboard>Discussion Groups</a>
  <li><a href=/file-storage/>Shared Files</a> 
  <li><a href=reports/status/>Status Report</a>
  <p><li><a href=/register/logout>Log Out</a>

</ul>

</td><td valign=top>[im_random_employee_blurb]</td>
</tr></table>
"

set info_about_you "
<ul>
  <li><a href=users/view>Your public information</a>
  <li><a href=employees/payroll>Your HR information</a>
  <li><a href=absences/one-user>Work absences</a>
  <li><a href=/pvt/alerts>Your alerts</a> (<a href=/pvt/unsubscribe>Unsubscribe</a>)
  <li><a href=/pvt/password-update>Change your password</a>
" 

if { $portrait_exists_p } {
    append info_about_you "  <li><a href=/pvt/portrait/>Your portrait</a>\n"
} else {
    append info_about_you "  <li><a href=/pvt/portrait/upload>Upload your portrait</a>\n"
}

append info_about_you "</ul>\n"

set page_body "
<table width=100% cellpadding=0 cellspacing=2 border=0>
<tr>
  <td valign=top>
$left_column
  </td>
  <td valign=top>
[im_table_with_title  "Need a <a href=task-board>task</a>?" "$task_blurb</ul>"]
[im_table_with_title "Tasks and Tickets" "
<ul>
<li><a href=/ticket/>Ticket Tracker</a>
<li><a href=/ticket/project-summary?return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0&public=yes>Project summary</a>
</ul>"
]

[im_table_with_title "Projects" "<ul>$projects</ul>"]
[im_table_with_title "Customers" "<ul>$customers</ul>"]
"
if { ![empty_string_p $hours] } {
    append page_body [im_table_with_title "Work Logs" $hours]
} 

if { $user_admin_p } {
    set admin_info "
<ul>
  <li> <a href=employees/admin>Employee administration</a>
  <li> <a href=absences/>Work absences</a>
</ul>"

    db_foreach admin_groups_user_belongs_to \
	    "select ug.group_id, ug.group_name, ai.url as ai_url
               from  user_groups ug, administration_info ai
              where ug.group_id = ai.group_id
                and ad_group_member_p ( :user_id, ug.group_id ) = 't'" {
	append admin_items "<li><a href=\"$ai_url\">$group_name</a>\n"
    }

    if [info exists admin_items] {
	append admin_info "
<b>Your administrative roles:</b>
<ul>
$admin_items
</ul>
<P>
"
}

    append page_body [im_table_with_title "Administration" $admin_info]
}

append page_body "
[im_table_with_title "Information about you" $info_about_you]
  </td>
</tr>
</table>
"



doc_return  200 text/html [im_return_template]
