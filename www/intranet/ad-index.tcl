# /www/intranet/ad-index.tcl

ad_page_contract {
    top level intranet page customized for ArsDigita

    @author mbryzek@arsdigita.com and many others
    @creation-date Mar 2000
    @param none

    @cvs-id ad-index.tcl,v 3.36.2.14 2000/09/22 01:38:20 kevin Exp
} {
    
}

set user_id [ad_maybe_redirect_for_registration]


# Redirect customers away
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if { $user_admin_p } {
    set user_customer_p 0
} else {
    set customer_group_id [im_customer_group_id]
    set user_customer_p [db_string user_customer_check \
            "select decode ( ad_group_member_p ( :user_id, :customer_group_id ), 'f', 0, 1 ) from dual" ]
}

# If this is a customer, go to the customer front page
if { $user_customer_p } {
    ad_return_error "Access Denied" "Sorry, but you need to be an employee of [ad_parameter SystemURL] to access the intranet"
    return
    # the customer portal is not yet build
    ad_returnredirect customers
    return
}

if { ![db_0or1row user_information \
	"select first_names || ' ' || last_name as full_name
           from users 
          where user_id=:user_id" ] } {

    ad_return_error "User doesn't exist" "We're sorry, but we can't find you in our database. You can <a href=/register/logout>logout</a> and try logging in again."
    return
}

set portrait_exists_p [db_0or1row portrait_info  "
   select portrait_id 
     from general_portraits
    where on_what_id = :user_id
      and upper(on_which_table) = 'USERS'
      and approved_p = 't'
"]
set page_title "${full_name}'s workspace at [ad_parameter SystemName]"
set context_bar [ad_context_bar [list / Home] "Your workspace"]

set projects ""
set sql "select ug.group_name, ug.group_id
           from user_groups ug, im_projects p
          where ad_group_member_p ( :user_id, ug.group_id ) = 't'
            and ug.group_id=p.group_id
            and p.project_status_id in (select project_status_id
                                          from im_project_status 
                                         where project_status='Open' 
                                            or project_status='Future' )
          order by lower(group_name)"

db_foreach projects_user_belongs_to $sql {
    append projects "  <li> <a href=projects/view?[export_url_vars group_id]>$group_name</a>\n"
} 

if { ![empty_string_p $projects] } {
    append projects "<p>"
}

append projects "  <li> <a href=projects/index?mine_p=f>All projects</a>\n"



set customers ""
set sql "select ug.group_name, ug.group_id
           from user_groups ug, im_customers c
          where ad_group_member_p ( :user_id, ug.group_id ) = 't'
            and ug.group_id=c.group_id
            and c.customer_status_id in (select customer_status_id 
                                          from im_customer_status 
                                         where customer_status in ('Current','Inquiries','Creating Bid','Bid out'))
          order by lower(group_name)"

db_foreach customers_user_belongs_to $sql {
    append customers "  <li> <a href=customers/view?[export_url_vars group_id]>$group_name</a>\n"
}
if { ![empty_string_p $customers] } {
    append customers "<p>"
}
append customers "  <li> <a href=customers/index?view_type=all>All customers</a>\n"


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

# This sucks to hardcode a short name, but I don't know how else to do it
set business_links ""
set group_member_p [db_string user_business_group_member \
	"select decode(count(1),0,0,1) 
           from user_groups ug
          where ad_group_member_p ( :user_id, ug.group_id ) = 't'
            and ug.short_name='Business'" ]

if { $group_member_p } {
    set business_links "
  <li> <a href=/ticket/index?project_id=127>Business Ticket Tracker</a>
  <li> <a href=/file-storage/group?group_id=1541>Business Documents</a>
"
}

set group_member_p [db_string user_finance_group_member \
	"select decode(count(1),0,0,1) 
           from user_groups ug
          where ad_group_member_p ( :user_id, ug.group_id ) = 't'
            and ug.short_name='Finance'" ]

if { $group_member_p } {
    append business_links "  <li> <a href=/file-storage/group?group_id=1542>Finance Documents</a>\n"
}

if { ![empty_string_p $business_links] } {
    append business_links "<p>\n"
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
append news " <li> <a href=$news_dir/index?archive_p=1>archives</a>\n"


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

[im_late_project_reports $user_id]
<P><em><a href=\"/news/\">[ad_parameter SystemName] News</a></em>
<ul>
  $news
</ul>

<form method=get name=employee_search action=employees/search>
<table width=100%>
<tr><td valign=top>

<ul>
<li>adfasdlkfjhasdflkjhs
<li><a href=/ischecker>IS Checker</a> - Machine tracking and monitoring</a>
<li><a href=/dev-tracker>Development Tracker</a> - Record and manage tasks for your projects
<li><a href=/wp>Wimpy Point</a> - Collaborative presentations
<p>
  $business_links

  <li><a href=employees/>Employees</A> (<a href=employees/org-chart>org chart</a>)
  <br><font size=-1>
      Search: <input type=text name=keywords size=20>
  <br><input name=search_type type=submit value=\"Search\"> 
      <input name=search_type type=submit value=\"Feeling Lucky\"></font></form>
 
  <p>
  <li><a href=offices/>Offices</a>
  <li><a href=facilities/>Facilities</a>
  <ul><li><a href=\"/reservations/ch/\">Reserve</a> a bed.</li>
  <li><a href=\"/reservations/cr/\">Reserve</a> a conference room.</li>
  </ul>
  <li><a href=/ad-training>ArsDigita Training Center</a>
  <li><a href=/ad-sysadmin>Sysadmin</a> - NOC and sysadmin (server emergencies)
  <li><a href=partners/>Partners</a>
  <li><a href=procedures/>Procedures</A>
  <li><a href=/job-listings>Job Listings</a>
  <p>
  <!-- <li><a href=/address-book/index?scope=public>Address book: [ad_parameter IntranetName intranet]</a> -->
  <li><a href=/address-book/>Address Book: Private</a>
  <li>Bookmarks: <a href=/bookmarks/>Private</a> / <a href=/bookmarks/public-bookmarks>Public</a>
  $monthly_calendar_link
  <li><a href=/directory>Directory</a>
  <p>
  <li><a href=/ad-developer>Developer Resources</a>  
  <li><a href=/bboard>Discussion Groups</a>
  <p>
  <li><a href=/documents>ArsDigita Documents</a> 
  <li><a href=/file-storage/>Shared Files</a> 

  <li><a href=/intranet/reports/>ArsDigita Reports</a>
  <p>
  <li><a href=/pvt/password-update>Change my password</a>

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
<p>
<b>Swat Team Requests</b>
<ul>
<li><a href=/ticket/issue-new?project_id=2341&return_url=%2Fticket%2Findex%3F>AOL 3.0 issues</a>
<li><a href=/ticket/issue-new?project_id=2343&return_url=%2Fticket%2Findex%3F>Scaling problems</a>
</ul>
<p>
Submit ticket for:
<li><a href=/ticket/issue-new?project_id=500&return_url=%2fticket%2findex%2etcl%3fproject%5fid%3d500%26domain%5fid%3dall%26submitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0>ArsDigita.com</a> -  
intranet and extranet (arsdigita.com is the URL)

<li> <a href=/ticket/issue-new?project_id=130&return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0%26project%5fid%3d130%26domain%5fid%3dall>Administrative Support</a> 


<li> <a href=/ticket/issue-new?project_id=620&return_url=%2Fticket%2Findex%3Fproject_id%3D620%26domain_id%3Dall%26submitby%3Dany%26assign%3Dany%26status%3Dactive%26created%3Dany%26default_orderby%3Dpriority%26expert%3D0>Facilities</a> - buildings (new and old)

<li> <a href=/ticket/issue-new?project_id=126&return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0%26project%5fid%3d126%26domain%5fid%3dall>Marketing</a> - publicity and public image

<li> <a href=/ticket/issue-new?project_id=125&return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0%26project%5fid%3d125%26domain%5fid%3dall>Client Services</a> - issues involving clients and projects;
escalations; general client concerns

<li> <a href=/ticket/issue-new?project_id=1360&return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0%26project%5fid%3d1360%26domain%5fid%3dall>Operations</a> - issues involving procedures, or team/office needs

<li> <a href=/ticket/issue-new?project_id=122&return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0%26project%5fid%3d122%26domain%5fid%3dall>HR, Boot Camps, Recruiting, Orientation, Payroll, Benefits</a> - new or potential employees and tracking employee information

<li> <a href=/ticket/issue-new?project_id=160&return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0%26project%5fid%3d160%26domain%5fid%3dall>Sales</a> - Sales leads and tracking, including contract renegotiations

<li> <a href=/ticket/issue-new?project_id=120&return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0%26project%5fid%3d120%26domain%5fid%3dall>Computer and System Administration</a> - involves a computer (Note: Don't ask for desktop
support if you can do it yourself)

<li> <a href=/sdm/>Toolkit</a> - Toolkit bugs and development

<li> <a href=/ticket/issue-new?project_id=2040&return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0%26project%5fid%3d2040%26domain%5fid%3dall>New project ideas OR projects needing assignment</a> - Ideas for new projects or for restructuring old ones

<li> <a href=/ticket/issue-new?project_id=&return_url=%2fticket%2findex%2etcl%3fdomain%5fid%3dall%26project%5fid%3d%26submitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0>Other</a>

<li>Ticket Questions? Ask <a href=mailto:bcameros@arsdigita.com>Brian Cameros</a>.
</ul>"
]

[im_table_with_title "Core ArsDigita Documentation" " 
<ul>
<li><a href=http://www.arsdigita.com/wp/display/22>ArsDigita and You: Working Together</a> - document for our customers
<li><a href=http://www.arsdigita.com/wp/display/5621>Hosting at ArsDigita</a> 
</ul>
"
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
  <li> <a href=vacations/>Work absences</a>
</ul>"

    set sql "select ug.group_id, ug.group_name, ai.url as ai_url
from  user_groups ug, administration_info ai
where ug.group_id = ai.group_id
and ad_group_member_p ( :user_id, ug.group_id ) = 't'"

    db_foreach admin_group_list $sql {
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

