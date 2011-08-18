# $Id: view.tcl,v 3.5.2.3 2000/03/17 07:26:14 mbryzek Exp $
#
# File: /www/intranet/employess/admin/view.tcl
# Author: mbryzek@arsdigita.com, Jan 2000
# Adminstrative view of one employees
# 

ad_maybe_redirect_for_registration

set_form_variables 0
# user_id 
# return_url optional

if { ![exists_and_not_null user_id] } {
    ad_return_error "Missing user id" "We weren't able to determine what user you want information for."
    return
}

if { ![exists_and_not_null return_url] } {
    set return_url [ad_partner_url_with_query]
}

set caller_user_id $user_id 
set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
select 
  u.first_names, 
  u.last_name, 
  u.email, 
  u.bio,
  decode(u.user_state,'banned','banned','deleted','deleted','') as user_state,
  info.*, 
  referral.user_id as referral_id,
  referral.first_names || ' ' || referral.last_name as referral_name,
  supervisors.user_id as supervisor_user_id, 
  supervisors.first_names || ' ' || supervisors.last_name as supervisor_name,
  featured_employee_blurb,
  featured_employee_approved_p
from users u, im_employee_info info, users supervisors, users referral
where u.user_id = $user_id
and u.user_id = info.user_id(+)
and info.referred_by = referral.user_id(+)
and ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'
and info.supervisor_id = supervisors.user_id(+)"]

if [empty_string_p $selection] {
    ad_return_error "Error" "That user doesn't exist"
    return
}
set_variables_after_query

# We keep offices separate as their is a chance of having more than one right now (because
# of our use of the user_group_map table
set selection [ns_db select $db \
	"select ug.group_name, ug.group_id
           from user_groups ug
          where ad_group_member_p ( $caller_user_id, ug.group_id ) = 't'
            and ug.parent_group_id = [im_office_group_id]"]

set office ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { ![empty_string_p $office] } {
	append office ", "
    }
    append office "  <a href=../../offices/view.tcl?[export_url_vars group_id]>$group_name</A>\n"
}




proc display_salary {salary salary_period} {

    set display_pref [im_salary_period_display]

    switch $salary_period {
        month {
	    if {$display_pref == "month"} {
                 return "[format %6.2f $salary] per month"
            } elseif {$display_pref == "year"} {
                 return "\$[format %6.2f [expr $salary * 12]] per year"
            } else {
                 return "\$[format %6.2f $salary] per $salary_period"
            }
        }
        year {
	    if {$display_pref == "month"} {
                 return "[format %6.2f [expr $salary/12]] per month"
            } elseif {$display_pref == "year"} {
                 return "\$[format %6.2f $salary] per year"
            } else {
                 return "\$[format %6.2f $salary] per $salary_period"
            }
        }
        default {
            return "\$[format %6.2f $salary] per $salary_period"
        }
    }
}

set page_title "$first_names $last_name"
set context_bar [ad_context_bar [list "/" Home] [list ../../index.tcl "Intranet"] [list index.tcl "Employees"] "One employee"]

ns_db releasehandle $db

ReturnHeaders
ns_write [ad_partner_header]

if { [empty_string_p $job_title] } {
    set job_title "<em>(No information)</em>"
}

if [empty_string_p $salary] {
    set salary "<em>(No information)</em>"
} else {
    set salary [display_salary $salary $salary_period]
}

if { ![empty_string_p $supervisor_user_id] } {
    set supervisor_link "<a href=view.tcl?user_id=$supervisor_user_id>$supervisor_name</a>"
} else {
    set supervisor_link "<em>(No information)</em>"
}

ns_write "<UL>
<LI>Job title: $job_title
<li>Office: $office
<LI>Supervisor:  $supervisor_link 
(<a href=update-supervisor.tcl?user_id=$caller_user_id>update</a>)
<LI>Salary: $salary
 -- <A HREF=../payroll.tcl?user_id=$caller_user_id&[export_url_vars return_url]>payroll information</A>
<li>Team leader? [util_decode t $team_leader_p "Yes" "No"]
<li>Project lead? [util_decode t $project_lead_p "Yes" "No"]
<li>Referred by: "

if { ![empty_string_p $referred_by] } {
    set target "[im_url_stub]/employees/admin/info-update-referral.tcl"
    set passthrough "return_url employee_id"
    set employee_id $caller_user_id
    ns_write "<a href=[im_url_stub]/users/view.tcl?user_id=$referral_id>$referral_name</a> 
(<a href=../../user-search.tcl?[export_url_vars passthrough target return_url employee_id]>update</a> | 
 <a href=info-update-referral.tcl?user_id_from_search=&[export_url_vars employee_id return_url]>clear</a> )\n"
}

ns_write "

<li>Percentage:  $percentage (<a href=history.tcl?user_id=$caller_user_id>history</a>)

<li>Job description: $job_description
<li>Start date: [util_AnsiDatetoPrettyDate $start_date]
<li>Manages group: $group_manages
<li>Received offer letter: [util_decode t $received_offer_letter_p "Yes" "No"]
<li>Returned offer letter: [util_decode t $returned_offer_letter_p "Yes" "No"]
<li>Signed confidentiality agreement: [util_decode t $signed_confidentiality_p "Yes" "No"]
<li>Most recent review: [util_AnsiDatetoPrettyDate $most_recent_review]
<li>Most recent review in folder? : [util_decode t $most_recent_review_in_folder_p "Yes" "No"]
<li>Biography: 
<blockquote>
$bio
</blockquote>
<li> Years experience: $years_experience
<li> Eductional history: $educational_history
<li> Last degree completed: $last_degree_completed
<li>Featured Employee Blurb:
<blockquote>
$featured_employee_blurb
</blockquote>
<li>Blurb approved? [util_decode t $featured_employee_approved_p "Yes" "No"]
<p>
(<a href=info-update.tcl?user_id=$caller_user_id>edit</a>)

</ul>
"

if { ![empty_string_p $user_state] } {
    ns_write "This user is currently <a href=/admin/users/one.tcl?user_id=$caller_user_id>$user_state</a>."
} else {
    ns_write "If this person has left the company, you can <a href=user-remove.tcl?user_id=$caller_user_id&[export_url_vars return_url]>remove</a> him/her from all intranet groups, or you can 
<a href=/admin/users/delete.tcl?user_id=$caller_user_id&[export_url_vars return_url]>ban him/her from the system</a>.
"

}

ns_write [ad_partner_footer]
