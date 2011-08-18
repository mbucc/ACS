# /www/intranet/index.tcl
#
# Purpose: top level, portal-like page, for employees, for the intranet
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# $Id: index.tcl,v 3.12.2.5 2000/04/28 15:11:04 carsten Exp $

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# Redirect customers away
set user_admin_p [im_is_user_site_wide_or_intranet_admin $db $user_id]
if { $user_admin_p } {
    set user_customer_p 0
} else {
    set user_customer_p [database_to_tcl_string $db \
            "select decode ( ad_group_member_p ( $user_id, [im_customer_group_id] ), 'f', 0, 1 ) from dual"]
}

# If this is a customer, go to the customer front page
if { $user_customer_p } {
    ad_return_error "Access Denied" "Sorry, but you need to be an employee of [ad_parameter SystemURL] to access the intranet"
    return
    # the customer portal is not yet build
    ad_returnredirect customers.tcl
    return
}

set selection [ns_db 0or1row $db \
	"select first_names || ' ' || last_name as full_name, 
                decode(portrait_upload_date,NULL,0,1) as portrait_exists_p
           from users 
          where user_id=$user_id"]
if { [empty_string_p $selection] } {
    ad_return_error "User doesn't exist" "We're sorry, but we can't find you in our database. You can <a href=/register/logout.tcl>logout</a> and try logging in again."
    return
}
set_variables_after_query

set page_title "${full_name}'s workspace at [ad_parameter SystemName]"
set context_bar [ad_context_bar "Intranet"]



set projects ""
set selection [ns_db select $db \
	"select ug.group_name, ug.group_id
           from user_groups ug, im_projects p
          where ad_group_member_p ( $user_id, ug.group_id ) = 't'
            and ug.group_id=p.group_id
            and p.project_status_id in (select project_status_id
                                          from im_project_status 
                                         where project_status='Open' 
                                            or project_status='Future' )
          order by lower(group_name)"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append projects "  <li> <a href=projects/view.tcl?[export_url_vars group_id]>$group_name</a>\n"
}
if { ![empty_string_p $projects] } {
    append projects "<p>"
}

append projects "  <li> <a href=projects/index.tcl?mine_p=f>All projects</a>\n"



set customers ""
set selection [ns_db select $db \
	"select ug.group_name, ug.group_id
           from user_groups ug, im_customers c
          where ad_group_member_p ( $user_id, ug.group_id ) = 't'
            and ug.group_id=c.group_id
            and c.customer_status_id in (select customer_status_id 
                                          from im_customer_status 
                                         where customer_status in ('Current','Inquiries','Creating Bid','Bid out'))
          order by lower(group_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append customers "  <li> <a href=customers/view.tcl?[export_url_vars group_id]>$group_name</a>\n"
}
if { ![empty_string_p $customers] } {
    append customers "<p>"
}
append customers "  <li> <a href=customers/index.tcl?mine_p=f>All customers</a>\n"


if { [ad_parameter TrackHours intranet 0] } {
    set on_which_table "im_projects"
    set num_hours [hours_sum_for_user $db $user_id $on_which_table "" 7]
    if { $num_hours == 0 } {
	append hours "<b>You haven't logged your hours in the last week. Please <a href=hours/index.tcl?[export_url_vars on_which_table]>log them now</a></b>\n"
    } else {
	append hours "You logged $num_hours [util_decode $num_hours 1 hour hours] in the last 7 days."
    }
    append hours "
<ul>
  <li><a href=hours/projects.tcl?[export_url_vars on_which_table user_id]>View your hours on all projects</a>
  <li><a href=hours/total.tcl?[export_url_vars on_which_table]>View time spent on all projects by everyone</a>
  <li><a href=hours/projects.tcl?[export_url_vars on_which_table]>View the hours logged by someone else</a>
  <li><a href=hours/index.tcl?[export_url_vars on_which_table]>Log hours</a>
</ul>
" 
} else {
    set hours ""
}

set return_url [ad_partner_url_with_query]
set since_when [database_to_tcl_string $db "select sysdate - 30 from dual"]
set news [news_new_stuff $db $since_when 0 "web_display" 1 0 [im_employee_group_id]]
set news_dir [im_groups_url -short_name [ad_parameter EmployeeGroupShortName intranet employee] -section news]

if { [ad_parameter ApprovalPolicy news] == "open"} {
    append news "\n<li><a href=\"$news_dir/post-new.tcl?scope=group&[export_url_vars return_url]\">post an item</a>\n"
} elseif { [ad_parameter ApprovalPolicy news] == "wait"} {
    append news "\n<li><a href=\"$news_dir/post-new.tcl?scope=group&[export_url_vars return_url]\">suggest an item</a>\n"
}
append news " | <a href=$news_dir/index.tcl?scope=group&archive_p=1>archives</a>\n"

set left_column "

[im_late_project_reports $db $user_id]
<P><em><a href=\"/news/\">[ad_parameter SystemName] News</a></em>
<ul>
  $news
</ul>

<form method=post action=employees/search.tcl>
<table width=100%>
<tr><td valign=top>
<ul>
  <li><a href=employees/index.tcl>Employees</A> (<a href=employees/org-chart.tcl>org chart</a>)
  <br><font size=-1>
      Search: <input type=text name=keywords size=20>
  <br><input name=search_type type=submit value=\"Search\"> 
      <input name=search_type type=submit value=\"Feeling Lucky\"></font></form>
 
  <p>
  <li><a href=offices/index.tcl>Offices</a>
  <li><a href=partners/index.tcl>Partners</a>
  <li><a href=procedures/index.tcl>Procedures</A>
  <p>
  <!-- <li><a href=/address-book/index.tcl?scope=public>Address book: [ad_parameter IntranetName intranet]</a> -->
  <li><a href=/address-book/index.tcl>Address Book: Private</a>
  <li><a href=/calendar/monthly.tcl>Calendar (monthly view with vacations!)</a>
  <li><a href=/directory>Directory</a>
  <p>
  <li><a href=/bboard>Discussion Groups</a>
  <li><a href=/file-storage/index.tcl>Shared Files</a> 
  <li><a href=status-report.tcl>Status Report</a>
  <p><li><a href=/register/logout.tcl>Log Out</a>

</ul>

</td><td valign=top>[im_random_employee_blurb $db]</td>
</tr></table>
"

set info_about_you "
<ul>
  <li><a href=users/view.tcl>Your public information</a>
  <li><a href=employees/payroll.tcl>Your HR information</a>
  <li><a href=vacations/one-user.tcl>Work absences</a>
  <li><a href=/pvt/alerts.tcl>Your alerts</a> (<a href=/pvt/unsubscribe.tcl>Unsubscribe</a>)
  <li><a href=/pvt/password-update.tcl>Change your password</a>
" 

if { $portrait_exists_p } {
    append info_about_you "  <li><a href=/pvt/portrait/index.tcl>Your portrait</a>\n"
} else {
    append info_about_you "  <li><a href=/pvt/portrait/upload.tcl>Upload your portrait</a>\n"
}

append info_about_you "</ul>\n"

set page_body "
<table width=100% cellpadding=0 cellspacing=2 border=0>
<tr>
  <td valign=top>
$left_column
  </td>
  <td valign=top>
[im_table_with_title "Tasks and Tickets" "
<ul>
<li><a href=/ticket/index.tcl>Ticket Tracker</a>
<li><a href=/ticket/project-summary.tcl?return_url=%2fticket%2findex%2etcl%3fsubmitby%3dany%26assign%3dany%26status%3dactive%26created%3dany%26orderby%3dmsg%255fid%252a%26expert%3d0&public=yes>Project summary</a>
</ul>"
]

[im_table_with_title "Projects" "<ul>$projects</ul>"]
[im_table_with_title "Customers" "<ul>$customers</ul>"]
"
if { ![empty_string_p $hours] } {
    append page_body [im_table_with_title "Work Logs" $hours]
} 

if { $user_admin_p } {
    append page_body [im_table_with_title "Administration" "
<ul>
  <li> <a href=employees/admin>Employee administration</a>
  <li> <a href=vacations/>Work absences</a>
</ul>
"]
}


append page_body "
[im_table_with_title "Information about you" $info_about_you]
  </td>
</tr>
</table>
"


ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]

