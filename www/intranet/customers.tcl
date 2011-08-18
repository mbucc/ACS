# $Id: customers.tcl,v 3.1.4.1 2000/03/17 08:22:39 mbryzek Exp $
#
# File: /www/intranet/customers.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: top-level page for our customers to gain information 
#  about their projects and the ArsDigitans working for them
#  This page intended to provide a complete snapshot of everything
#  on the intranet in which this customer would be interested

set_form_variables 0
# show_all_comments

set return_url [ad_partner_url_with_query]

set current_user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select 
  first_names, 
  last_name, 
  email, 
  url, 
  portrait_upload_date,
  portrait_client_file_name,
  nvl(screen_name,'&lt none set up &gt') as screen_name
from users 
where user_id=$current_user_id"]

if [empty_string_p $selection] {
    ad_return_error "Account Unavailable" "We can't find you (user #$current_user_id) in the users table.  Probably your account was deleted for some reason.  You can visit <a href=\"/register/logout.tcl\">the log out page</a> and then start over."
    return
}

set_variables_after_query

if { ![empty_string_p $first_names] || ![empty_string_p $last_name] } {
    set full_name "$first_names $last_name"
} else {
    set full_name "name unknown"
}

if [ad_parameter SolicitPortraitP "user-info" 0] {
    # we have portraits for some users 
    set portrait_chunk "<h4>Your Portrait</h4>\n"
    if { ![empty_string_p $portrait_upload_date] } {
	append portrait_chunk "On [util_AnsiDatetoPrettyDate $portrait_upload_date], you uploaded <a href=\"/pvt/portrait/\">$portrait_client_file_name</a>."
    } else {
	append portrait_chunk "Show everyone else at [ad_system_name] how great looking you are:  <a href=\"/pvt/portrait/upload.tcl?[export_url_vars return_url]\">upload a portrait</a>"
    }
} else {
    set portrait_chunk ""
}

set page_title "Projects with [ad_parameter SystemName]"
set context_bar [ad_context_bar [list "/" Home] "Your workspace"]

# Let's get a list of each project, and the employees who work on that project

set all_projects [database_to_tcl_list_list $db \
	"select ug.group_name, ug.group_id
           from user_groups ug, user_group_map ugm
          where ug.parent_group_id=[im_project_group_id]
            and ug.group_id=ugm.group_id(+)
            and ugm.user_id=$current_user_id"]

set projects "<ul>\n"
if { [llength $all_projects] == 0 } {
    append projects "<li><em>none</em>\n"    
} else {
    foreach pair $all_projects {
	set group_name [lindex $pair 0]
	set group_id [lindex $pair 1]
	append projects "
  <li> <b>$group_name</b>
  <ul>
    <li>Employees working on this project:
     <ul>[im_users_in_group $db $group_id $current_user_id Employees 0 $return_url [im_employee_group_id] [im_customer_group_id]]</ul>
  </ul>
  <ul>
    <li>Progress reports:
"
    if { [exists_and_not_null show_all_comments] } {
	set progress_reports [ad_general_comments_summary_sorted $db $group_id im_projects $group_name]
    } else {
	set url_for_more "[im_url_stub]/customers.tcl?show_all_comments=1&[export_ns_set_vars url [list show_all_comments]]"
	set progress_reports [ad_general_comments_summary_sorted $db $group_id im_projects $group_name 5 $url_for_more]
    }
    append projects "
$progress_reports
   </ul>
"
    }
}
append projects "</ul>\n"


set left_column "
$projects

<h3>Information about you</h3>

<ul>
<li>Name:  $full_name
<li>email address:  $email 
<li>personal URL:  <a target=new_window href=\"$url\">$url</a>
<li>screen name:  $screen_name
<p>
(<a href=\"/pvt/basic-info-update.tcl?[export_url_vars return_url]\">update</a>)
  <p><li><a href=/pvt/password-update.tcl?[export_url_vars return_url]>Change my password</a>
  <p><li><a href=/register/logout.tcl>Log Out</a>
</ul>

$portrait_chunk
"


set page_body $left_column

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]
