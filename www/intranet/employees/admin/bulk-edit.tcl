
# /www/intranet/employees/admin/bulk-edit.tcl

ad_page_contract {
    Adminstrative view of all employees
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id bulk-edit.tcl,v 3.6.2.9 2000/09/22 01:38:32 kevin Exp

    @param group_id Optional parameter to specify the group.  
    @param status_id Optional parameter to specify the group.  
} {
    group_id:optional,integer
    status_id:optional,integer
}

set urlvars ""

#we may want to append some vars..
catch {append urlvars "?[export_entire_form_as_url_vars]"} 

set return_url "[ns_conn url]$urlvars"
set user_id [ad_maybe_redirect_for_registration]

set view_types "<b>Admin View</b> | <a href=../org-chart>Org Chart</a> | <a href=../index>Standard View</a>"

set page_title "Employees"
set context_bar [ad_context_bar_ws $page_title]

set body "
[im_header]


<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr><td align=right>$view_types</td></tr>
</table>

"

set team_list_list [db_list_of_lists get_teams "select group_id, group_name
from user_groups where parent_group_id = [im_team_group_id]"]


set office_list_list [db_list_of_lists get_offices "select group_id, group_name
from user_groups where parent_group_id = [im_office_group_id]"]

set prior_experience_id_options [db_html_select_value_options prior_exp_sel_query "select experience_id, experience from im_prior_experiences order by lower(experience)"]

set source_id_options [db_html_select_value_options source_id_sel_query "select  source_id, source from im_hiring_sources order by lower(source)"]

set job_id_options [db_html_select_value_options job_id_sel_query "select job_title_id, job_title from im_job_titles order by lower(job_title)"]

set department_id_options [db_html_select_value_options department_id_options_query "select department_id, department from im_departments order by lower(department)"]

set qualification_id_options [db_html_select_value_options qualification_id_options_query "select qualification_id, qualification from im_qualification_processes order by lower(qualification)"]


if ![empty_string_p group_id] {
    set users_view "select users_active.user_id, users_active.last_name, users_active.first_names 
                    from users_active, user_group_map
                    where users_active.user_id = user_group_map.user_id
                    and user_group_map.group_id = :group_id"
    set viewing_group_id $group_id
} else {
    set users_view "select user_id, last_name, first_names from users_active"
    set viewing_group_id ""
}

set missing_html "<em>missing</em>"

set thequery "select u.user_id, u.last_name || ', ' || u.first_names as name, 
(select '<option value=' || im_hiring_sources.source_id  || ' selected>'|| source || '</option>' as source_option 
from im_employee_info, im_hiring_sources 
where im_employee_info.user_id = u.user_id and im_hiring_sources.source_id = im_employee_info.source_id) 
as source_option,
(select '<option value=' || im_job_titles.job_title_id  || ' selected>'|| im_job_titles.job_title || '</option>' as original_job_option from im_employee_info, im_job_titles where im_employee_info.user_id = u.user_id and im_job_titles.job_title_id = im_employee_info.original_job_id) 
as original_job_option,
(select '<option value=' || im_job_titles.job_title_id  || ' selected>'|| im_job_titles.job_title || '</option>' as current_job_option from im_employee_info, im_job_titles where im_employee_info.user_id = u.user_id and im_job_titles.job_title_id = im_employee_info.current_job_id) 
as current_job_option,
(select '<option value=' || im_prior_experiences.experience_id  || ' selected>'|| im_prior_experiences.experience || '</option>' as prior_experience_option from im_employee_info, im_prior_experiences where im_employee_info.user_id = u.user_id and im_prior_experiences.experience_id = im_employee_info.experience_id) 
as prior_experience_option,
(select '<option value=' || im_departments.department_id  || ' selected>'|| im_departments.department || '</option>' as department_option from im_employee_info, im_departments where im_employee_info.user_id = u.user_id and im_departments.department_id = im_employee_info.department_id) 
as department_option,
(select '<option value=' || im_qualification_processes.qualification_id  || ' selected>'|| im_qualification_processes.qualification || '</option>' as qualifiation_option from im_employee_info, im_qualification_processes where im_employee_info.user_id = u.user_id and im_qualification_processes.qualification_id = im_employee_info.qualification_id) 
as qualification_option
from ($users_view) u, im_employee_info info, user_group_map ugm
          where u.user_id = ugm.user_id
            and ugm.group_id = [im_employee_group_id]
            and u.user_id = info.user_id(+) 
       order by upper(name)" 


set ctr 0
set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""

db_foreach getpeople $thequery {
    append results "

<tr$bgcolor([expr $ctr % 2])>
  <td valign=top> 
<a href=view?[export_url_vars user_id]>$name</a>
<br>
Previous company/position
<select name=experience_id.$user_id>
$prior_experience_option
<option></option>
$prior_experience_id_options 
</select>
Source of hire:
<select name=source_id.$user_id>
$source_option
<option></option>
$source_id_options
</select>
<br>
Original job:
<select name=original_job_id.$user_id>
$original_job_option
<option></option>
$job_id_options
</select>
Current job:
<select name=current_job_id.$user_id>
$current_job_option
<option></option>
$job_id_options
</select>
<br>
Department:
<select name=department_id.$user_id>
$department_option
<option></option>
$department_id_options
</select>
Qualification:
<select name=qualification_id.$user_id>
$qualification_option
<option></option>
$qualification_id_options
</select>
 </font></td></tr>"
}

db_release_unused_handles


if { [empty_string_p $results] } {
    set results "<ul><li><b> There are currently no employees</b></ul>\n"
} else {
    set results "
<br>
<table width=100% cellpadding=1 cellspacing=2 border=0>
$results
</table>
"
}
append team_string "Team: "

foreach team $team_list_list {
    set group_id [lindex $team 0]
    set group_name [lindex $team 1]
    if {$viewing_group_id == $group_id} {
	append team_string "$group_name | "
    } else {
	append team_string "<a href=bulk-edit?group_id=$group_id>$group_name</a> | "
    }
}


set office_string "Office: "

foreach office $office_list_list {
    set group_id [lindex $office 0]
    set group_name [lindex $office 1]
    if {$viewing_group_id == $group_id} {
	append office_string "$group_name | "
    } else {
	append office_string "<a href=bulk-edit?group_id=$group_id>$group_name</a> | "
    }
}


append body "
$team_string <br>
$office_string <br>
<form action=bulk-edit-2 method=post>
[export_form_vars return_url]
$results
<center>
<input type=submit name=submit value=\"Edit\">
</center>
</form>
<p> 

[im_footer]
"
doc_return  200 text/html $body


