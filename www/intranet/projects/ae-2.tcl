# /www/intranet/projects/ae-2.tcl

ad_page_contract {
    Purpose: verifies and stores project information to db

    @param return_url the url to return to
    @param group_id group id
    @param dp_ug.user_groups.creation_ip_address the ip address of the user who created this project
    @param dp_ug.user_groups.creation_user user_id of the user who created this project
    @param dp_ug.user_groups.group_name project name
    @param dp_ug.user_groups.short_name project short name
    @param dp.im_projects.customer_id customer id
    @param dp.im_projects.project_type_id project type id
    @param dp.im_projects.project_status_id project status id
    @param dp.im_projects.project_lead_id user_id of the project lead
    @param dp.im_projects.supervisor_id user_id of the project supervisor
    @param dp.im_projects.parent_id parent project id
    @param dp.im_projects.description project description
    @param dp.im_projects.requires_report_p whether the project requires weekly report
    @param start    
    @param end
    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id ae-2.tcl,v 3.10.2.15 2001/01/12 16:54:05 khy Exp
} {
    return_url:optional
    group_id:integer,optional,verify
    dp_ug.user_groups.creation_ip_address:optional
    dp_ug.user_groups.creation_user:integer,optional
    dp_ug.user_groups.group_name:optional
    dp_ug.user_groups.short_name:optional
    dp_ug.user_groups.existence_public_p:optional
    dp.im_projects.customer_id:integer,optional
    dp.im_projects.project_type_id:integer,optional
    dp.im_projects.project_status_id:integer,optional
    dp.im_projects.project_lead_id:integer,optional
    dp.im_projects.supervisor_id:integer,optional
    dp.im_projects.parent_id:integer,optional
    dp.im_projects.description:optional
    dp.im_projects.requires_report_p:optional
    start:array,date,notnull
    end:array,date,notnull
    dp.im_projects.start_date:optional
    dp.im_projects.end_date:optional
    dp_ug.user_groups.group_id:integer,optional
    dp_ug.user_groups.group_type:optional
    dp_ug.user_groups.approved_p:optional
    dp_ug.user_groups.new_member_policy:optional
    dp_ug.user_groups.parent_group_id:integer,optional
    dp_ug.user_groups.modification_date.expr:optional
    dp_ug.user_groups.modifying_user:optional
    dp_ug.user_groups.existence_public_p:optional
    dp.im_projects.group_id:integer,optional
}

set user_id [ad_maybe_redirect_for_registration]

# Log who's making changes and when
set todays_date [db_string projects_get_date "select sysdate from dual"]

set required_vars [list \
	[list "dp_ug.user_groups.group_name" "You must specify the project name"] \
	[list "dp.im_projects.customer_id" "You must specify the customer"] \
	[list "dp.im_projects.project_type_id" "You must specify the project type"] \
	[list "dp_ug.user_groups.short_name" "You must specify the project short name"]\
	[list "dp.im_projects.project_status_id" "You must specify the project status"]]

set errors [im_verify_form_variables $required_vars]
if { [empty_string_p $errors] == 0 } {
    set err_cnt 1
} else {
    set err_cnt 0
}

# check for not null start date
if { [info exists start(date) ] } {
   set start_date $start(date)
} else {
   incr err_cnt
   append errors "<li> Please make sure the start date is not empty"
}

# check for not null end date 
if [info exists end(date)] {
   set end_date $end(date)
} else {
   incr err_cnt
   append errors "<li> Please make sure the end date is not empty"
}

# make sure end date after start date
if { ![empty_string_p $end_date] && ![empty_string_p $start_date] } {
    set difference [db_string projects_get_date_difference \
	    "select to_date(:end_date,'YYYY-MM-DD') - to_date(:start_date,'YYYY-MM-DD') from dual"]
    if { $difference < 0 } {
	incr err_cnt
	append errors "  <li> End date must be after start date\n"
    }
}

# Let's make sure the specified short name is unique
set short_name ${dp_ug.user_groups.short_name}
set short_name_exists_p [db_string projects_check_name_exists \
	"select decode(count(1),0,0,1) 
           from user_groups 
          where short_name=:short_name
            and group_id <> :group_id" ]


if { $short_name_exists_p > 0 } {
    incr err_cnt
    append errors "  <li> The specified short name, \"${dp_ug.user_groups.short_name},\" already exists - please select another, unique short name\n"
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $err_cnt $errors
    return
}

set form_setid [ns_getform]
ns_set put $form_setid "dp.im_projects.start_date" $start_date
ns_set put $form_setid "dp.im_projects.end_date" $end_date

# Create/update the user group frst since projects reference it
# Note: group_name, creation_user, creation_date are all set in ae.tcl
ns_set put $form_setid "dp_ug.user_groups.group_id" $group_id
ns_set put $form_setid "dp_ug.user_groups.group_type" [ad_parameter IntranetGroupType intranet]
ns_set put $form_setid "dp_ug.user_groups.approved_p" "t"
ns_set put $form_setid "dp_ug.user_groups.new_member_policy" "closed"
ns_set put $form_setid "dp_ug.user_groups.parent_group_id" [im_project_group_id]

# Log the modification date
ns_set put $form_setid "dp_ug.user_groups.modification_date.expr" sysdate
ns_set put $form_setid "dp_ug.user_groups.modifying_user" $user_id

# Make projects non-visible so surfing users can't see them from /groups
ns_set put $form_setid dp_ug.user_groups.existence_public_p "f"

# Put the group_id into projects. This is also used for the where clause
ns_set put $form_setid "dp.im_projects.group_id" $group_id

set bind_vars [ns_set create]
ns_set put $bind_vars group_id $group_id

db_transaction {
    
    # Update user_groups
    dp_process -form_index "_ug" -where_clause "group_id=:group_id"
    
    # Now update im_projects
    dp_process -where_clause "group_id=:group_id"

}

db_release_unused_handles

if { ![exists_and_not_null return_url] } {
    set return_url "[im_url_stub]/projects/view?[export_url_vars group_id]"
}

if { [exists_and_not_null dp.im_projects.project_lead_id] } {
    # Need to add the project leader as well
    set return_url "[im_url_stub]/member-add-3?[export_url_vars group_id return_url]&user_id_from_search=${dp.im_projects.project_lead_id}&role=administrator"
}

ad_returnredirect $return_url






