# /www/intranet/projects/view.tcl

ad_page_contract {
    View all the info about a specific project

    @param group_id the group id
    @param orderby the display order
    @param show_all_comments whether to show all comments

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id view.tcl,v 3.50.2.18 2001/02/06 02:10:06 mbryzek Exp
} {
    group_id:integer
    {orderby "subproject_name"}
    {show_all_comments 0}
}

set current_user_id [ad_maybe_redirect_for_registration]

set return_url [im_url_with_query]

# Admins and Employees can administer projects
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if { $user_admin_p == 0 } {
    set user_admin_p [im_user_is_employee_p $current_user_id]
}

# We need to check if the Dev-Tracker is installed.
if { ![empty_string_p [ad_parameter "DevTrackerInstalledP" "DevTracker" ""]] } {
    set query "select dt_group_id_project_id(g.group_id) as dev_tracker_project_id, "
} else {
    set query "select "
}

append query   "p.*, g.group_name as project_name, 
                g.short_name, p.parent_id, p.customer_id,
                g2.group_name as customer_name, 
                im_project_ticket_project_id(g.group_id) as ticket_project_id,               
                user_group_name_from_id(p.parent_id) as parent_name,
                l.first_names||' '||l.last_name as project_lead, project_lead_id, 
                s.first_names||' '||s.last_name as supervisor,
                m.first_names||' '||m.last_name as manager, m.user_id as manager_id,
                im_category_from_id(p.project_type_id) as project_type, 
                im_category_from_id(p.project_status_id) as project_status
           from im_projects p, im_customers c, users l, users s, users m, user_groups g, user_groups g2
          where p.project_lead_id=l.user_id(+)
            and p.customer_id = c.group_id
            and c.manager = m.user_id(+)
            and p.group_id=:group_id
            and p.supervisor_id=s.user_id(+)
            and p.group_id=g.group_id
            and p.customer_id=g2.group_id(+)" 

if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "Can't find the project with group id of $group_id"
    return
}

if { $user_admin_p > 0 || $current_user_id == $project_lead_id } {
    # Set up all the admin stuff here in an array
    set admin(edit_project) "  <p><li><a href=ae?[export_url_vars group_id return_url]>Edit this project</a>"
} else {
    set admin(edit_project) ""
}


set ticket_string "<li> <a href=ticket-edit?[export_url_vars group_id return_url]>Create a ticket tracker</a>\n"
set ticket_string_2 ""

if { $ticket_project_id == 0 } {
    set ticket_string "<li> <a href=ticket-edit?[export_url_vars group_id]>Create a ticket tracker</a>\n"
} else {
    set num_new [db_string projects_tickets_number_open \
	    "select count(i.msg_id) 
               from ticket_issues i
              where sysdate - i.POSTING_TIME < 3
                and i.project_id=:ticket_project_id" -default 0]
    set ticket_string "  <li> <a href=/ticket/index?project_id=$ticket_project_id>[util_decode $num_new 0 "No new tickets" 1 "1 new ticket" "$num_new new tickets"] in the last 24 hours</a>\n"
}



# Check if a Dev-Tracker project exists for this Intranet project. - Kai 5/01/00
if { ![empty_string_p [ad_parameter "DevTrackerInstalledP" "DevTracker" ""]]  } {
    if { $dev_tracker_project_id == 0 } {
        set dev_tracker_string "<li> <a href=/dev-tracker/project-ae?[export_url_vars group_id return_url]>Create a dev-tracker</a>\n"
    } else {
        set dev_tracker_string "<li> <a href=/dev-tracker/project-overview?[export_url_vars dev_tracker_project_id]>Go to dev-tracker overview</a>\n"
    }
} else {
    set dev_tracker_string ""
}

set merge_group_id_1 $group_id
set mine_p "f"
set merge_string "<li><a href=\"index?[export_url_vars merge_group_id_1 mine_p]\">merge with another project</a>"


set left_column "
<font size=-1>
<ul>
  <li> Customer: <a href=[im_url_stub]/customers/view?group_id=$customer_id>$customer_name</a>
"

if { [empty_string_p $parent_id] } {
    set context_bar [ad_context_bar_ws [list index "Projects"] "One project"]
    set include_subproject_p 1
} else {
    set context_bar [ad_context_bar_ws [list index "Projects"] [list "view?group_id=$parent_id" "One project"] "One subproject"]
    append left_column "  <li> Parent Project: <a href=view?group_id=$parent_id>$parent_name</a>\n"
    set include_subproject_p 0
}

append left_column "
  <li> Project leader: <a href=[im_url_stub]/users/view?user_id=$project_lead_id>$project_lead</a>
  <li> Team leader or supervisor: <a href=[im_url_stub]/users/view?user_id=$supervisor_id>$supervisor</a>
  <li> Client Service Representative: <a href=[im_url_stub]/users/view?user_id=$manager_id>$manager</a>
[im_email_aliases $short_name]
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
    
    append left_column "  <li> Requires project report? [util_PrettyBoolean $requires_report_p]\n"
}

if { $user_admin_p > 0 } {
    append left_column "
<form action=ae method=post>
[export_form_vars group_id return_url]
<input type=submit name=submit value=\"Edit\">
</form>

</ul>
</ul>
<h4>Tracking</h4>
<ul>
<li><a href=[im_url_stub]/payments/index?[export_url_vars group_id]>Payments</a>
<li><a href=[im_url_stub]/allocations/one-group-one-month?[export_url_vars group_id]>Allocations</a>
</ul>
"
} 

# Change subprojects to use ad_table
# This table display Subproject Name, Project Leader, Hours, Staff
set table_def [list \
    [list subproject_name "Subproject Name"  \
       {lower(group_name) $order} \
       {<td><a href="view?group_id=$subgroup_id">$subproject_name</a></td>} \
   ] \
    [list project_lead "Project Leader"  \
       {lower(last_name) $order} \
       {<td><a href="[im_url_stub]/users/view?user_id=$project_lead_id">$project_lead</a></td>} \
   ] \
    [list total_hours "Hours"  \
       {} \
       {<td>$total_hours</td>} \
   ] \
    [list total_staff "Staff"  \
       {} \
       {<td>$total_staff</td>} \
   ] \
]

if { $include_subproject_p } {
    append left_column "
<p><h4>Subprojects</h4>
"
    # Have to do a complete outer join on im_hours, user_groups and 
    # user_group_map to get staff count correct
    # This explicitly selects for status of Open or Future, should probably
    # be a parameter somewhere
   
    set sql \
	"select p.group_id as subgroup_id, g.group_name as subproject_name, 
                u.first_names||' '||u.last_name as project_lead, project_lead_id,
                sum(nvl(h.hours,0)) as total_hours,
                count(distinct m.user_id) as total_staff
           from im_projects p, user_groups g, users u, im_hours h, user_group_map m, 
                  im_project_status s

          where p.parent_id = :group_id
            and p.group_id = g.group_id(+)
            and p.project_status_id = s.project_status_id
            and s.project_status in ('Open','Future')
            and p.project_lead_id = u.user_id(+)
            and p.group_id = m.group_id(+)
            and m.user_id = h.user_id(+)
            and 'im_projects' = h.on_which_table(+)
            and m.group_id = h.on_what_id(+)
          group by p.group_id, g.group_name, u.first_names, u.last_name, project_lead_id
          [ad_order_by_from_sort_spec $orderby $table_def]"
    
    #gotta use ns_set here because ad_table needs it 
    set bind_vars [ns_set create]
    ns_set put $bind_vars group_id $group_id
    append left_column [ad_table -Torderby $orderby -bind $bind_vars projects_info_query $sql $table_def]

    if { $user_admin_p > 0 } {
	append left_column "  <p><a href=ae?[export_url_vars subproject]&parent_id=$group_id&customer_id=$customer_id>Add a subproject</a>\n"
    }
}

if { $include_subproject_p  && 0} {
    append left_column "
<p><b>Subprojects</b>
<ul>
"

    set sql \
	"select p.group_id as subgroup_id, g.group_name as subproject_name
           from im_projects p, user_groups g
          where p.parent_id=:group_id
            and p.group_id=g.group_id
          order by lower(g.group_name)" 

    db_foreach project_list_subgroups $sql  {
	append left_column "  <li><a href=view?group_id=$subgroup_id>$subproject_name</a>\n"
	incr ctr
    } if_no_rows {
	append left_column "  <li> <i>None</i>\n"
    }

    if { $user_admin_p > 0 } {
	append left_column "  <p><li> <a href=ae?[export_url_vars subproject]&parent_id=$group_id&customer_id=$customer_id>Add a subproject</a>\n"
    }

    append left_column "</ul>\n"
}

append left_column "
</ul>
</font>
"

set user_in_project_group_p [db_string user_belongs_to_project \
    "select decode ( ad_group_member_p ( :current_user_id, $group_id ), 'f', 0, 1 ) from dual" ]

if { $user_admin_p } {
    ## HOURS LOGGED
    set total_hours [hours_sum im_projects $group_id]

    set hours_logged "
<ul>
  <li>[util_commify_number $total_hours] [util_decode $total_hours 0 "hour has" 1 "hour has" "hours have"] been spent on this project
"
    if { $include_subproject_p } {
	set subproject_hours [db_string hours_on_subprojects \
		"select nvl(sum(hours), 0)
                   from im_hours
                  where on_what_id in (select group_id from im_projects where parent_id = :group_id)
                    and on_which_table = 'im_projects'" ]
	
	append hours_logged "
  <li>$subproject_hours [util_decode $subproject_hours 0 "hour has" 1 "hour has" "hours have"] been spent on this project's subprojects"
    }

    if { $total_hours > 0 } {
	append hours_logged "  <li><a href=[im_url_stub]/hours/one-project?on_what_id=$group_id&on_which_table=[ad_urlencode im_projects]>See the breakdown by person</a>\n"
    }
    if { $user_in_project_group_p } {
	append hours_logged "  <li><a href=[im_url_stub]/hours/ae?on_what_id=$group_id&on_which_table=[ad_urlencode im_projects]&[export_url_vars return_url]>Log your hours</a>\n"
    }
    append hours_logged "</ul>\n"
}

## PROJECT Notes
set project_notes ""

if { [exists_and_not_null show_all_comments] && $show_all_comments } {
    append project_notes [ad_general_comments_summary_sorted $group_id user_groups $project_name]
} else {
    set url_for_more "[im_url_stub]/projects/view?show_all_comments=1&[export_ns_set_vars url [list show_all_comments]]"
    append project_notes [ad_general_comments_summary_sorted $group_id user_groups $project_name 5 $url_for_more]
}




## Links to associated bboards
set bboard_string ""
if { [ad_parameter BBoardEnabledP intranet 0] } {
    set sql "select topic, topic_id, presentation_type
               from bboard_topics
              where group_id=:group_id
                 or group_id=:customer_id
              order by lower(topic)"

    db_foreach project_bboard_topics $sql  {
	set link [bboard_complete_backlink $topic_id $topic $presentation_type]
	regsub {href="} $link {href="/bboard/} link
	append bboard_string "  <li> $link\n"
    } if_no_rows {
	set bboard_string "  <li> <em>none</em>\n"
    }
}


# project reports

set project_report ""

# Project reports are stored using the survsimp module
# Get the survey_id of the survey.


set survey_short_name ""
#figure out if this type of project is in the list
foreach type_survey_pair  [ad_parameter_all_values_as_list ProjectReportTypeSurveyNamePair intranet] {
    set type_survey_list [split $type_survey_pair ","]
    set type [lindex $type_survey_list 0]
    set survey [lindex $type_survey_list 1]
    if {[string tolower $project_type] == [string tolower $type]} {
	set survey_short_name $survey
    }
}


if {![empty_string_p $survey_short_name]} {
    set survey_id  [survsimp_survey_short_name_to_id $survey_short_name]
   
    if {![empty_string_p $survey_id]} {
	# figure out the latest response date for this group

	if { [db_0or1row project_report_last_submitted \
		"select sr.response_id, sr.submission_date as latest_submission_date, 
                        u.first_names || ' ' || u.last_name as name, u.user_id
	         from survsimp_responses sr, users u
	         where sr.survey_id = :survey_id
	         and sr.user_id = u.user_id
	         and sr.group_id = :group_id
     	         and sr.submission_date = (select max(sr2.submission_date) 
	                                     from survsimp_responses sr2 
	                                    where sr2.survey_id = :survey_id
                                      	      and sr2.group_id = :group_id)" ] } {

	    append project_report "[survsimp_answer_summary_display $response_id 1]"
	    append project_report  "<p><a href=/survsimp/one-respondent?[export_url_vars survey_id group_id]>Audit of all reports</a><p>"
	    set table_title "Latest project report: [util_AnsiDatetoPrettyDate $latest_submission_date] by <a href=[im_url_stub]/users/view?[export_url_vars user_id]>$name</a>"
	} else {
	    set table_title "Latest project report"
	}

	
	set return_url [im_url_with_query]

	append project_report "<a href=/survsimp/one?[export_url_vars survey_id group_id return_url]>Add a report</a>"
	

	append left_column "[im_table_with_title $table_title "$project_report"]"
    }
}



set page_body  "
<table width=100% cellpadding=0 cellspacing=2 border=0>
<tr>
  <td valign=top>
$left_column
  </td>

  <td valign=top>
[im_table_with_title "Project Management" "<ul>$ticket_string [util_decode $user_in_project_group_p 0 "" "<p> <li><a href=\"/file-storage/private-one-group?group_id=$group_id\">Project Files</a>\n"] <p> $dev_tracker_string <p> $merge_string</ul>"]

[im_table_with_title "Employees" "<ul>[im_users_in_group $group_id $current_user_id "Spam employees working on $project_name" $user_admin_p $return_url [im_employee_group_id] "" "" $customer_id]</ul>"]

[im_table_with_title "Customers" "<ul>[im_users_in_group $group_id $current_user_id "Spam customers working on $project_name" $user_admin_p $return_url [im_customer_group_id] [im_employee_group_id]]</ul>"]

[util_decode $bboard_string "" "" [im_table_with_title "Discussion Groups" "<ul>$bboard_string</ul>"]]
"

if { $user_admin_p } {
    append page_body [im_table_with_title "Hours logged" $hours_logged]
} 

if [empty_string_p $survey_short_name] {
    append page_body "
[im_table_with_title "Project Reports" $project_notes]

<ul>
<p><a href=\"/general-comments/comment-add?group_id=$group_id&scope=group&on_which_table=user_groups&on_what_id=$group_id&item=Projects&module=intranet&[export_url_vars return_url]\">Add a project report</a>
</ul>
</font>
"
} else {
    # project types that don't have a particular survey type attached
    # use the general comment system for the project reports
    append page_body "
[im_table_with_title "Project Notes" $project_notes]
<ul>
<p><a href=\"/general-comments/comment-add?group_id=$group_id&scope=group&on_which_table=user_groups&on_what_id=$group_id&item=Projects&module=intranet&[export_url_vars return_url]\">Add a project note</a>
</ul>
</font>
"
}

append page_body "
  </td>
</tr>
</table>
"

db_release_unused_handles

set page_title $project_name
doc_return  200 text/html [im_return_template]
