# /www/intranet/employees/admin/pipeline-list.tcl

ad_page_contract {
    
    manage the employee pipeline 
    this page will get more refined, right now, it just a quick list of upcoming
    people   

    @author teadams@arsdigita.com
    @creation-date April 26, 2000
    @cvs-id pipeline-list.tcl,v 3.13.2.10 2000/09/22 01:38:34 kevin Exp
    @param office_group_id Optional The group id
    @param job_listing_id Optional The job listing id
    @param orderby Optional An order by clause
} {
    {office_group_id:integer "0" }
    {job_listing_id:integer "-1"}
    {orderby "projected_start_date"}
}


##Create the job listing slider

set job_listing_list [list]

db_foreach get_job_stuff "select jl.listing_id, jl.title from job_listings jl where jl.deleted_p = 'f' and jl.ticket_project_id is not null order by upper(jl.title)" {

    if {$job_listing_id == -1} {
        set job_listing_id $listing_id
    }

    lappend job_listing_list $listing_id $title

} if_no_rows {
    #If there aren't any job listings, set it to 0
    set job_listing_id 0
}


lappend job_listing_list 0 "All"
set job_listing_slider [im_slider job_listing_id $job_listing_list $job_listing_id]
set jl_where [util_decode $job_listing_id 0 "" " im_employee_pipeline.job_listing_id = $job_listing_id and"]

##Create the office slider

set office_list [list "0" "All"]
db_foreach select_group_stuff "select ug.group_id, ug.group_name
           from user_groups ug
          where ug.parent_group_id = [im_office_group_id]" {
    lappend office_list $group_id $group_name
}

set office_slider [im_slider office_group_id $office_list $office_group_id ""]


##Table definition for ad_table
set table_def { 
    {full_name "Name" {} {<td><a href=pipeline-ae?backlink_url=[ns_urlencode /intranet/employees/admin/pipeline-list]&backlink_url_name=Pipeline&[export_url_vars user_id]>$full_name</a></td>} } \
    {office "Office" {} {} } \
}

if { $job_listing_id == 0 } {
    set table_def [concat $table_def {
        {state "State" {} {} } \
        {job_title "Job Title" {} {} } \
        {job_listing "Job Listing" {} {<td align=center><a href=[ns_conn url]?job_listing_id=$job_listing_id>$job_listing</a>}} \
        {projected_start_date "Projected Start Date" {} {} } \
        {probability "Probability" {} {} } \
        {note "Note" {} {} } \
            }]
}

proc display_one_ticket { msg_id status deadline assignee_count assignee } {
    if { [string compare $status "Closed"] == 0 } {
        set desc "done" 
    } else {
        set desc "[util_decode $assignee_count "" "" 0 "Unassigned" 1 $assignee "$assignee, ..."] [util_decode $deadline "" "" ": $deadline"] $status"
    }
    set return_url [ns_conn url]?[export_ns_set_vars]
    return "<td align=center><a href=/ticket/issue-view?[export_url_vars msg_id return_url]>$desc</a></td>"
}


##Create the extra SQL clauses and table definitions for each ticket domain.
set extra_from ""
set extra_where ""
set extra_selections ""

set ticket_links [list]
if { $job_listing_id != 0 } {
    #Get the ticket domains used for that listing
    
    set count 0
    db_foreach get_project_stuff "select map.project_id, map.domain_id, td.title_long  from job_listings, ticket_domain_project_map map, ticket_domains td
           where job_listings.listing_id = :job_listing_id and
                 job_listings.ticket_project_id = map.project_id and
                 map.domain_id = td.domain_id" {

        lappend ticket_links "<a href=/ticket/index?[export_url_vars project_id domain_id]>$title_long</a> ticket tracker"
        set table_name "ti[set count]"
        set table_sub_name "tisub[set count]"

        #This subquery selects the relevant information from the ticket in a given domain
        #It is made complex by the fact that we want only the most recent version
        set ti_view "select $table_name.one_line, $table_name.deadline,
                            $table_name.status, $table_name.msg_id,
                            (select count(*) from ticket_issue_assignments tia1 where tia1.msg_id = $table_name.msg_id) as num_assignees,
                            (select first_names || ' ' || last_name from users where user_id = tia.user_id) as assignee_name
                     from ticket_issues $table_name,
                          ticket_issue_assignments tia
                     where tia.msg_id(+) = $table_name.msg_id
                           and $table_name.project_id = :project_id
                           and $table_name.domain_id = :domain_id
                           and $table_name.posting_time =
                               (select max(posting_time) from ticket_issues $table_sub_name
                                where $table_sub_name.project_id = :project_id
                                      and $table_sub_name.domain_id = :domain_id
                                      and $table_sub_name.one_line = $table_name.one_line)
                           and (tia.user_id is null or tia.user_id  = (select max(user_id) from ticket_issue_assignments where msg_id = $table_name.msg_id))"
        append extra_from ", ($ti_view) tiv$count "
        append extra_where " and tiv$count.one_line(+) = first_names || ' ' || last_name || ' (' || email || ')'  "
        append extra_selections ", tiv$count.deadline as deadline$count, tiv$count.status as status$count, tiv$count.msg_id as msg_id$count, tiv$count.num_assignees as num_assignees$count, tiv$count.assignee_name as assignee_name$count"

        #Note that these are somewhat complex since we are building up strings to be interpreted,
        # so we have to escape various things (but not the $count)
        lappend table_def [list "status$count" "$title_long" "assignee_name$count \$order, deadline$count \$order" "\[display_one_ticket \$msg_id$count \$status$count \$deadline$count \$num_assignees$count \$assignee_name$count\]"]

        incr count 1
    }
}


# note, we don't want to select those that have been fully hired
# and put in the employees table
# we don't need to worry about bind vars here.. none of the variables can be edited by the user
# the ones passed into the page can only be integers, and thus are protected 


## The statements below are to turn empty query rows into comments, so that the sql parser won't choke. -MJS 7/25

set util_decode_results [util_decode $office_group_id 0 "" "im_employee_pipeline.office_id = $office_group_id and"]

if {[empty_string_p $util_decode_results]} {set util_decode_results "--"}
if {[empty_string_p $extra_selections]} {set extra_selections "--"}
if {[empty_string_p $extra_from]} {set extra_from "--"}
if {[empty_string_p $extra_where]} {set extra_where "--"}
if {[empty_string_p $jl_where]} {set jl_where "--"}


set thequery "
select im_employee_pipeline.*, im_employee_pipeline.probability_to_start as probability,
im_employee_pipeline_states.state,
user_groups.group_name as office,
im_job_titles.job_title,
job_listings.listing_id as job_listing_id,
job_listings.title as job_listing,
first_names || ' ' || last_name as full_name,
users.user_id,
(select count(*) from survsimp_responses sr where sr.user_id = users.user_id and sr.survey_id = job_listings.survey_id) as num_surveys,
job_listings.survey_id
$extra_selections
from im_employee_pipeline, users, im_employee_pipeline_states, user_groups, im_job_titles, job_listings
$extra_from
where users.user_id = im_employee_pipeline.user_id and
im_employee_pipeline.state_id = im_employee_pipeline_states.state_id(+) and
im_employee_pipeline.office_id = user_groups.group_id(+) and
im_employee_pipeline.job_id = im_job_titles.job_title_id(+) and
im_employee_pipeline.job_listing_id = job_listings.listing_id(+) and
$jl_where
$util_decode_results
-- we do not want to select those that have been fully hired
not exists (select 1 
              from im_employees_active emp
             where users.user_id = emp.user_id)
$extra_where [ad_order_by_from_sort_spec $orderby $table_def]"

## Note: Look into ad_order_by_from_sort_spec
## and find out why it's prepending a \n

# Add two bind vars to the ns_set
set bind_vars [ns_set create]
ns_set put $bind_vars project_id [value_if_exists project_id]
ns_set put $bind_vars domain_id [value_if_exists domain_id]

set pipeline_string [ad_table -bind $bind_vars -Torderby $orderby table_pipeline_query $thequery $table_def]


set page_title "Employee pipeline"
set context_bar [ad_context_bar_ws [list ./ "Employees"] "Pipeline"]

set page_content "

<table width=100% cellpadding=0 cellspacing=2 border=0>
  <tr bgcolor=eeeeee>
    <th>Office</th>
    <th>Job Listings</th>
  </tr>
  <tr>
    <td align=center valign=top><font size=-1>$office_slider</font></td>
    <td align=center valign=top><font size=-1>$job_listing_slider</font></td>
  </tr>
</table>

<table>
$pipeline_string
</table>

<ul>
  [util_decode $job_listing_id "0" "" "<li> <a href=/job-listings/one?listing_id=$job_listing_id>Job Listing Page</a>"]
  [util_decode [llength $ticket_links] 0 "" <li>] [join $ticket_links "<li>"]
  <li> <h4>Add a person</h4>
       <form method=get action=/user-search>
       <input type=hidden name=\"return_url\" value=\"/intranet/employees/admin/pipeline-list\">
       <input type=hidden name=\"userid_returnas\" value=\"user_id\">
       <input type=hidden name=target value=\"/intranet/employees/admin/pipeline-ae\">
       <input type=hidden name=passthrough value=\"return_url\">
       <table border=0>
       <tr><td>Email address:<td><input type=text name=email size=40></tr>
       <tr><td colspan=2>or by</tr>
       <tr><td>Last name:<td><input type=text name=last_name size=40></tr>
       </table>
       <p>
       <center>
       <input type=submit value=Add>
       </center>
       </form>
       </ul>
"
doc_return  200 text/html [im_return_template]

## END FILE pipeline-list.tcl
