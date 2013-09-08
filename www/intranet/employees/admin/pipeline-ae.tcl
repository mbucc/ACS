# /www/intranet/employees/admin/pipeline-ae.tcl

ad_page_contract {

    Display selectboxes containing info about the applicant.  Also includes
    Hiring Process Checkpoints, Email Correspondence, Aplicant Provided Information,
    and links to edit the category_types Previous Positions, Job Titles, and 
    Hiring Sources.

    @author teadams@arsdigita.com
    @creation-date April 26, 2000
    @cvs-id pipeline-ae.tcl,v 3.10.2.23 2000/09/22 01:38:34 kevin Exp
    
    @param user_id            This must be provided
} {
    user_id:naturalnum    
    { return_url "" }
}

## Get name, etc. from users table and verify user_id

if { ![db_0or1row get_info_for_user "
select
  u.first_names, 
  u.last_name, 
  u.email,
  u.first_names || ' ' || u.last_name || ' (' || u.email || ')' as user_name_and_email
from users u 
where u.user_id = :user_id"] } {
    ad_return_error "Error" "That user doesn't exist"
    return
    
}


## Let's make sure this user isn't already an active employee. If they are, 
## display an error since they've already been hired.

set employee_sql {
    select decode(count(info.user_id),0,0,1)
      from im_employee_info info
     where info.user_id = :user_id
}

if { [db_string user_is_employee_p $employee_sql] } {
    ad_return_error "User is employee" "$user_name_and_email is already marked as an active employee. This user cannot be added to the recruiting pipeline."
    return
}



## Get info for this user currently in the im_employee_pipeline table

if {[db_0or1row select_info "select
im.user_id, im.state_id, im.office_id, im.team_id,
im.prior_experience_id, im.experience_id, im.source_id,
im.job_id, im.projected_start_date, im.recruiter_user_id,
im.referred_by, im.note, im.probability_to_start,
im.job_listing_id
from im_employee_pipeline im
where user_id = :user_id"] } {
    
    ## If we succeeded in retrieving the job_listing_id, then we can retrieve the survey_id
    if {[db_0or1row survey_id "select survey_id from job_listings where listing_id = :job_listing_id"] } {

	## If we succeeded in retrieving the survey_id, then we can retrieve num_surveys.  Can you believe this whole thing used to be a join?? -MJS 7/25
	db_1row num_surveys "select count(*) from survsimp_responses sr where sr.user_id = :user_id and sr.survey_id = :survey_id as num_surveys"
	
    } else {
	set survey_id ""
	set num_surveys 0
    }
} else {
    set survey_id ""
    set num_surveys 0
}



# We keep offices separate as their is a chance of having 
# more than one right now (because
# we have people associated with more than one office)

set list_of_group_types [list [ad_parameter OfficeGroupShortName intranet] [ad_parameter TeamGroupShortName intranet]]

foreach group_type $list_of_group_types {

    append group_message "
    <TR><TD ALIGN=RIGHT>Potential $group_type:</TD>  
    <TD><select name=[set group_type]_id>
    <option></option>
    [db_html_select_value_options -select_option [value_if_exists [set group_type]_id] user_groups_select_options "select group_id, group_name from user_groups where parent_group_id=[im_[set group_type]_group_id] order by lower(group_name)"]
    </select></TD></TR>"

}


## Survey Link - We probably shouldn't display this at all if the job_listing_id isn't set, but for now oh well. -MJS

set survey_link "$first_names $last_name has submitted $num_surveys applications."  

## Only provide the link to view applications if the user has submitted more than zero applications.
if {$num_surveys} {
    append survey_link "<a href=/survsimp/admin/one-respondent?user_id=$user_id&[export_url_vars survey_id]>View the applications.</a>"
}


set page_title "$first_names $last_name"



set context_bar [ad_context_bar_ws [list ./ "Employees"] [list "pipeline-list.tcl" "Pipeline"] "One Applicant"]



set backlink_url "[ns_conn url]?user_id=$user_id"
set backlink_url_name "$first_names $last_name"


set previous_position_url "category-list?category_html=[ns_urlencode "Previous Positions"]&[export_url_vars backlink_url backlink_url_name]"
set hiring_sources_url "category-list?category_html=[ns_urlencode "Hiring Sources"]&[export_url_vars backlink_url backlink_url_name]"
set original_job_url "category-list?category_html=[ns_urlencode "Job Titles"]&[export_url_vars backlink_url backlink_url_name]"


set page_content "
[im_header]

<h3>Our Information About the Applicant</h3>

<form action=pipeline-ae-2 method=post>
[export_form_vars backlink_url backlink_url_name return_url]
<input type=hidden name=user_id value=\"$user_id\">

<TABLE>

<TR><TD ALIGN=RIGHT>State</TD>
<TD><select name=state_id>
[db_html_select_value_options -select_option [value_if_exists state_id] make_state_select "select state_id, state from im_employee_pipeline_states order by lower(state)"]
</select>
</TD></TR>

$group_message

<TR><TD ALIGN=RIGHT>Previous company/position</TD>
<TD><select name=experience_id>
<option></option>
[db_html_select_value_options -select_option [value_if_exists experience_id] make_exp_select "select experience_id, experience from im_prior_experiences order by lower(experience)" ]
</select> <font size=-1><a href=$previous_position_url>maintain</a></font>
</TD></TR>
 
<TR><TD ALIGN=RIGHT>Source of hire:</TD>
<TD><select name=source_id>
<option></option>
[db_html_select_value_options -select_option [value_if_exists source_id] make_source_select "select source_id, source from im_hiring_sources order by lower(source)" ]
</select>  <font size=-1><a href=$hiring_sources_url>maintain</a></font>

<TR><TD ALIGN=RIGHT>Original Job:</TD>
<TD><select name=job_id>
<option></option>
[db_html_select_value_options -select_option [value_if_exists job_id] make_job_select "select job_title_id, job_title from im_job_titles order by lower(job_title)" ]
</select>  <font size=-1><a href=$original_job_url>maintain</a></font>
</TD></TR>

<TR><TD ALIGN=RIGHT>Projected start date:</TD><TD> [ad_dateentrywidget projected_start_date [value_if_exists projected_start_date]]</TD></TR>

<TR><TD ALIGN=RIGHT>Probability to join:</TD><TD> <input text name=probability_to_start size=3 value=[value_if_exists probability_to_start]></TD></TR>

<TR><TD ALIGN=RIGHT>Job Listing Used:</TD><TD>
<SELECT NAME=job_listing_id>
<OPTION></OPTION>
[db_html_select_value_options -select_option [value_if_exists job_listing_id] -option_index {{"" "----"}} job_listing_select_query "select listing_id,title from job_listings where deleted_p = 'f' order by upper(title)" ]
</SELECT>
</TD></TR>

<TR><TD ALIGN=RIGHT>Notes:</TD><TD> <textarea cols=30 rows=5 name=pipeline_note>[value_if_exists note]</textarea></TD></TR>

<TR><TD ALIGN=RIGHT>Confirm:</TD>
<TD><input type=submit name=submit value=\"Click Here\"></TD></TR>

</TABLE>

</form>
<p>

<h3>Applicant Provided Information</h3>

$survey_link

<h3>Hiring process checkpoints: <font size=-1>(<a href=checkpoint-add?stage=hiring_process&return_url=[ad_urlencode [im_url_with_query]]>add hiring process checkpoint</a>)</font> </h3>
<p>"


set checkstring ""

db_foreach checkpoints "
select checkpoint, 
       im_employee_checkpoints.checkpoint_id, 
       check_date, check_note, first_names, last_name,  
       checkee, im_emp_ccs.checker as checker
from   im_employee_checkpoints, 
       (select checkpoint_id, check_date, check_note, checker, checkee 
        from im_emp_checkpoint_checkoffs 
        where im_emp_checkpoint_checkoffs.checkee = :user_id) im_emp_ccs, 
       users
where  im_employee_checkpoints.checkpoint_id = im_emp_ccs.checkpoint_id (+)
and    stage = 'hiring_process'
and    users.user_id (+) = im_emp_ccs.checker" {

    append checkstring "<li>$checkpoint:"
    if {[empty_string_p $check_date]} {
	append checkstring " <a href=checkoff?return_url=[ad_urlencode [im_url_with_query]]&[export_url_vars checkpoint_id]&checkee=$user_id>Checkoff</a>"
    } else {
	append checkstring " $check_note  by <a href=/intranet/employees/admin/view?user_id=$checker>$first_names $last_name</a> on $check_date"
    }
}

append page_content "
<ul>
$checkstring
</ul>
"

##Check for tickets that are 
proc display_one_ticket { msg_id status deadline assignee_count assignee } {
    if { [string compare $status "Closed"] == 0 } {
        set desc "done" 
    } else {
        set desc "[util_decode $assignee_count "" "" 0 "Unassigned" 1 $assignee "$assignee, ..."] [util_decode $deadline "" "" ": $deadline"] $status"
    }
    set return_url [im_url_with_query]
    return "<td align=center><a href=/ticket/issue-view?[export_url_vars msg_id return_url]>$desc</a></td>"
}

if { ![empty_string_p [value_if_exists job_listing_id]] } {
    #Get the ticket domains used for that listing
    set tickets [db_list_of_lists gettickets \
	"select map.project_id, map.domain_id, td.title_long  
           from job_listings, ticket_domain_project_map map, ticket_domains td
           where job_listings.listing_id = :job_listing_id and
                 job_listings.ticket_project_id = map.project_id and
                 map.domain_id = td.domain_id"]
    set tick_results ""
    foreach tick $tickets {
        set project_id [lindex $tick 0]
        set domain_id [lindex $tick 1]
        set title_long [lindex $tick 2]
        set ticket_links "<a href=/ticket/index?[export_url_vars project_id domain_id]>$title_long</a> ticket tracker"

        #This subquery selects the relevant information from the ticket in a given domain
        #It is made complex by the fact that we want only the most recent version
        if {[db_0or1row ticket_issues "select ti.one_line, ti.deadline,
                            ti.status, ti.msg_id,
                            (select count(*) from ticket_issue_assignments tia1 where tia1.msg_id = ti.msg_id) as num_assignees,
                            (select first_names || ' ' || last_name from users where user_id = tia.user_id) as assignee_name
                     from ticket_issues ti,
                          ticket_issue_assignments tia
                     where tia.msg_id(+) = ti.msg_id
                           and ti.project_id = :project_id
                           and ti.domain_id = :domain_id
                           and ti.posting_time =
                               (select max(posting_time) from ticket_issues tisub
                                where tisub.project_id = :project_id
                                      and tisub.domain_id = :domain_id
                                      and tisub.one_line = ti.one_line)
                           and (tia.user_id is null or tia.user_id  = (select max(user_id) from ticket_issue_assignments where msg_id = ti.msg_id))
                           and ti.one_line = :user_name_and_email
        "]} {
            append tick_results "<li>$ticket_links: [display_one_ticket $msg_id $status $deadline $num_assignees $assignee_name]\n"
        }
    }
    if {![empty_string_p $tick_results]} {
        append page_content "<h3>Applicant Tickets</h3><ul>$tick_results</ul>"
    }
}

##Check to see if there are any email template messages that
##we can send this applicant.
append page_content "<h3>Email Correspondence</h3>"

if { ![empty_string_p [value_if_exists job_listing_id]] } {
    set sql "select t.email_template_name, t.email_template_id from job_listing_email_templates t, job_listing_email_template_map map where map.listing_id = $job_listing_id and t.email_template_id = map.email_template_id"
    set row_results "" 
    set return_url "[ns_conn url]?[export_url_vars user_id]"

    db_foreach email_templates $sql {

        append row_results "<li>$email_template_name (<a href=email-template-send?preview_p=t&[export_url_vars return_url email_template_id user_id]>Preview</a> | <a href=email-template-send?[export_url_vars return_url email_template_id user_id]>Send</a>)\n"
    }
    if {[empty_string_p $row_results]} {
	set row_results  "No rows found <p>"
    } else {
	set row_results "<ul>$row_results</ul>"
    }
    append page_content "Standard Recruiting Letters: $row_results"
}



set comments [ad_general_comments_summary $user_id "im_employee_pipeline" $page_title]
append comments "
<ul>
<p><a href=\"/general-comments/comment-add?on_which_table=im_employee_pipeline&on_what_id=$user_id&item=[ns_urlencode $page_title]&module=intranet&[export_url_vars return_url]\">Add a correspondence</a>
</ul>
"

append page_content "Previous Correspondences: $comments
[im_footer]"

doc_return  200 text/html $page_content

## END FILE pipeline-ae.tcl

