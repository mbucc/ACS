# $Id: view.tcl,v 3.7.2.6 2000/03/19 07:38:11 teadams Exp $
# File: /www/intranet/projects/view.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: View all the info about a specific project
#

set current_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id

set return_url [ad_partner_url_with_query]

set db [ns_db gethandle]


# Admins and Employees can administer projects
set user_admin_p [im_is_user_site_wide_or_intranet_admin $db $current_user_id]
if { $user_admin_p == 0 } {
    set user_admin_p [im_user_is_employee_p $db $current_user_id]
}

# set user_admin_p [im_can_user_administer_group $db $group_id $current_user_id]



set selection [ns_db 0or1row $db \
	"select p.*, g.group_name as project_name, g.short_name, p.parent_id, p.customer_id,
                g2.group_name as customer_name, im_project_ticket_project_id(g.group_id) as ticket_project_id,
                user_group_name_from_id(p.parent_id) as parent_name,
                l.first_names||' '||l.last_name as project_lead, project_lead_id, 
                s.first_names||' '||s.last_name as supervisor,
                im_proj_type_from_id(p.project_type_id) as project_type, 
                im_proj_status_from_id(p.project_status_id) as project_status
           from im_projects p, users l, users s, user_groups g, user_groups g2
          where p.project_lead_id=l.user_id(+)
            and p.group_id=$group_id
            and p.supervisor_id=s.user_id(+)
            and p.group_id=g.group_id
            and p.customer_id=g2.group_id(+)"]

if { [empty_string_p $selection] } {
    ad_return_complaint 1 "Can't find the project with group id of $group_id"
    return
}

set_variables_after_query


if { $user_admin_p > 0 || $current_user_id == $project_lead_id } {
    # Set up all the admin stuff here in an array
    set admin(edit_project) "  <p><li><a href=ae.tcl?[export_url_vars group_id return_url]>Edit this project</a>"
} else {
    set admin(edit_project) ""
}

if { $ticket_project_id == 0 } {
    set ticket_string "<li><a href=ticket-edit.tcl?[export_url_vars group_id return_url]>Create a ticket tracker</a>\n"
} else {
    set num_new [database_to_tcl_string_or_null $db \
	    "select count(1) 
               from ticket_issues i
              where sysdate - POSTING_TIME < 3
                and project_id=$ticket_project_id"]
    set ticket_string "  <li> <a href=/ticket/index.tcl?project_id=$ticket_project_id>[util_decode $num_new 0 "No new tickets" 1 "1 new ticket" "$num_new new tickets"] in the last 24 hours</a>\n"
}


set left_column "
[ad_partner_default_font "size=-1"]
<ul>
  <li> Customer: <a href=../customers/view.tcl?group_id=$customer_id>$customer_name</a>
"

if { [empty_string_p $parent_id] } {
    set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Projects"] "One project"]
    set include_subproject_p 1
} else {
    set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Projects"] [list "view.tcl?group_id=$parent_id" "One project"] "One subproject"]
    append left_column "  <li> Parent Project: <a href=view.tcl?group_id=$parent_id>$parent_name</a>\n"
    set include_subproject_p 0
}

append left_column "
  <li> Project leader: <a href=../users/view.tcl?user_id=$project_lead_id>$project_lead</a>
  <li> Team leader or supervisor: <a href=../users/view.tcl?user_id=$supervisor_id>$supervisor</a>
  <li> Project short name: $short_name <font size=-1>(eventually for things like email...)</font>
"

if { $user_admin_p > 0 } {
    append left_column "
  <li> Project Status: $project_status
  <li> Project Type: $project_type
"

    if { ![empty_string_p $start_date] } {
	append left_column "  <li> Start Date: [util_AnsiDatetoPrettyDate $start_date]\n"
    }
    if { ![empty_string_p $end_date] } {
	append left_column "  <li> End Date: [util_AnsiDatetoPrettyDate $end_date]\n"
    }
}


# Get the urls
set selection [ns_db select $db \
	"select m.url, t.to_display
           from im_url_types t, im_project_url_map m
          where m.group_id=$group_id
            and t.url_type_id=m.url_type_id
          order by t.display_order, lower(t.url_type)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { ![empty_string_p $url] } {
	set url [im_maybe_prepend_http $url]
	append left_column "  <li> $to_display: <a href=\"$url\">$url</a>\n"
    }
}


if { ![empty_string_p $description] } {
    append left_column "  <li> Description: $description\n"
}


if { $user_admin_p > 0 } {
    append left_column "
  <p><li><a href=ae.tcl?[export_url_vars group_id return_url]>Edit this project</a>

<p><a href=../payments/index.tcl?[export_url_vars group_id]>Payments</a>
<br><a href=../allocations/project.tcl?[export_url_vars group_id]>Allocations</a>
"
} 

if { $include_subproject_p } {
    append left_column "
<p><b>Subprojects</b>
<ul>
"

    set selection [ns_db select $db \
	"select p.group_id as subgroup_id, g.group_name as subproject_name
           from im_projects p, user_groups g
          where p.parent_id=$group_id
            and p.group_id=g.group_id"]
    set ctr 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append left_column "  <li><a href=view.tcl?group_id=$subgroup_id>$subproject_name</a>\n"
	incr ctr
    }
 
    if { $ctr == 0 } {
	append left_column "  <li> <i>None</i>\n"
    }

    if { $user_admin_p > 0 } {
	append left_column "  <p><li> <a href=ae.tcl?[export_url_vars subproject]&parent_id=$group_id&customer_id=$customer_id>Add a subproject</a>\n"
    }

    append left_column "</ul>\n"
}

append left_column "
</ul>
</font>
"

if { $user_admin_p } {
    ## HOURS LOGGED
    set total_hours [hours_sum $db im_projects $group_id]

    set hours_logged "
<ul>
  <li>$total_hours [util_decode $total_hours 1 "hour has" "hours have"] been spent on this project
"
    if { $total_hours > 0 } {
	append hours_logged "  <li><a href=../hours/one-project.tcl?on_what_id=$group_id&on_which_table=[ad_urlencode im_projects]>See the breakdown by person</a>\n"
    }
    set user_in_project_group_p [database_to_tcl_string $db \
				     "select decode ( ad_group_member_p ( $current_user_id, $group_id ), 'f', 0, 1 ) from dual"]
    if { $user_in_project_group_p } {
	append hours_logged "  <li><a href=../hours/ae.tcl?on_what_id=$group_id&on_which_table=[ad_urlencode im_projects]&[export_url_vars return_url]>Log your hours</a>\n"
    }
    append hours_logged "</ul>\n"
}

## PROJECT Notes
set project_notes [ad_partner_default_font "size=-1"]

if { [exists_and_not_null show_all_comments] } {
    append project_notes [ad_general_comments_summary_sorted $db $group_id im_projects $project_name]
} else {
    set url_for_more "[im_url_stub]/projects/view.tcl?show_all_comments=1&[export_ns_set_vars url [list show_all_comments]]"
    append project_notes [ad_general_comments_summary_sorted $db $group_id im_projects $project_name 5 $url_for_more]
}

append project_notes "
<ul>
<p><a href=\"/general-comments/comment-add.tcl?group_id=$group_id&scope=group&on_which_table=im_projects&on_what_id=$group_id&item=Projects&module=intranet&[export_url_vars return_url]\">Add a project comment</a>
</ul>
</font>
"


## Links to associated bboards
set bboard_string ""
set selection [ns_db select $db \
	"select topic, topic_id, presentation_type
           from bboard_topics
         where group_id=$customer_id"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set link [bboard_complete_backlink $topic_id $topic $presentation_type]
    regsub {href="} $link {href="/bboard/} link
    append bboard_string "  <li> $link\n"
}
if { [empty_string_p $bboard_string] } {
    set bboard_string "  <li> <em>none</em>\n"
}


# project reports

set project_report ""

# Project reports are stored using the survsimp module
# Get the survey_id of the survey.

set survey_short_name [ad_parameter ProjectReportSurveyName intranet ""]
 
if {![empty_string_p $survey_short_name]} {
   
    # figure out the survey_id from the short_name 
    set survey_id  [survsimp_survey_short_name_to_id $survey_short_name]
    
    if {![empty_string_p $survey_id]} {
	# figure out the latest response date for this group
    set response_id [database_to_tcl_string_or_null $db "select response_id
from survsimp_responses 
where survey_id = $survey_id
and group_id = $group_id
and submission_date = (select max(submission_date) from
survsimp_responses where survey_id = $survey_id 
                 and group_id = $group_id)"]

   
        if {![empty_string_p $response_id]} {
	    append project_report "[survsimp_answer_summary_display $db $response_id 1]"
	   append project_report  "<p><a href=/survsimp/one-respondent.tcl?[export_url_vars survey_id]>Audit of all reports</a>
<p>"
	} 

	
	set return_url "[ns_conn url]?[ns_conn query]"
	
	append project_report "<a href=/survsimp/one.tcl?[export_url_vars survey_id group_id return_url]>Add a report</a>"
	

	append left_column "[im_table_with_title "Latest project report" "$project_report"]"
    }
}



set page_body  "
<table width=100% cellpadding=0 cellspacing=2 border=0>
<tr>
  <td valign=top>
$left_column
  </td>
  <td valign=top>
[im_table_with_title "Ticket Tracker" "<ul>$ticket_string</ul>"]
[im_table_with_title "Employees" "<ul>[im_users_in_group $db $group_id $current_user_id "Spam employees working on $project_name" $user_admin_p $return_url [im_employee_group_id]]</ul>"]
[im_table_with_title "Customers" "<ul>[im_users_in_group $db $group_id $current_user_id "Spam customers working on $project_name" $user_admin_p $return_url [im_customer_group_id] [im_employee_group_id]]</ul>"]
[im_table_with_title "Discussion Groups" "<ul>$bboard_string</ul>"]
"
if { $user_admin_p } {
    append page_body [im_table_with_title "Hours logged" $hours_logged]
} 

append page_body "
[im_table_with_title "Project Notes" $project_notes]
  </td>
</tr>
</table>
"

ns_db releasehandle $db

set page_title $project_name
ns_return 200 text/html [ad_partner_return_template]