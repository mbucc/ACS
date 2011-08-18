# $Id: ae-2.tcl,v 3.3.2.2 2000/04/28 15:11:10 carsten Exp $
# File: /www/intranet/projects/ae-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: verifies and stores project information to db
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_the_usual_form_variables
# Bunch of stuff for dp

set form_setid [ns_getform]

set start_date "${ColValue.start.year}-${ColValue.start.month}-${ColValue.start.day}"
ns_set put $form_setid "dp.im_projects.start_date" $start_date

set end_date "${ColValue.end.year}-${ColValue.end.month}-${ColValue.end.day}"
ns_set put $form_setid "dp.im_projects.end_date" $end_date

set db [ns_db gethandle]

# Log who's making changes and when
set todays_date [database_to_tcl_string $db "select sysdate from dual"]

set required_vars [list \
	[list "dp_ug.user_groups.group_name" "You must specify the project name"] \
	[list "dp.im_projects.customer_id" "You must specify the customer"] \
	[list "dp.im_projects.project_type_id" "You must specify the project type"] \
	[list "dp.im_projects.project_status_id" "You must specify the project status"]]

set errors [im_verify_form_variables $required_vars]

# make sure end date after start date
if { ![empty_string_p $end_date] && ![empty_string_p $start_date] } {
    set difference [database_to_tcl_string $db \
	    "select to_date('$end_date','YYYY-MM-DD') - to_date('$start_date','YYYY-MM-DD') from dual"]
    if { $difference < 0 } {
	append errors "  <li> End date must be after start date\n"
    }
}

# Let's make sure the specified short name is unique
set short_name_exists_p [database_to_tcl_string $db \
	"select decode(count(1),0,0,1) 
           from user_groups 
          where short_name='[DoubleApos ${dp_ug.user_groups.short_name}]'
            and group_id <> $group_id"]


if { $short_name_exists_p > 0 } {
    append errors "  <li> The specified short name, \"${dp_ug.user_groups.short_name},\" already exists - please select another, unique short name\n"
}

if { ![empty_string_p $errors] } {
    ad_return_complaint 2 "<ul>$errors</ul>"
    return
}

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

# Put the group_id into projects
ns_set put $form_setid "dp.im_projects.group_id" $group_id

ns_db dml $db "begin transaction"

# Update user_groups
dp_process -db $db -form_index "_ug" -where_clause "group_id=$group_id"

# Now update im_projects
dp_process -db $db -where_clause "group_id=$group_id"

# Now we do the url's for this project

# Start by getting rid of the old URL's
ns_db dml $db "delete from im_project_url_map where group_id=$group_id"

foreach var [info vars "url_*"] {
    # Get the double-quoted value from the textbox named var
    set QQvar "QQ$var"
    set current_url [set ${QQvar}]
    # pull the url_type_id out of the name for the text box
    regexp {url_(.*)} $var match url_type_id
    # Insert the URL
    ns_db dml $db \
	    "insert into im_project_url_map
             (group_id, url_type_id,  url)
             values
             ($group_id, $url_type_id,  '$current_url')"

}

ns_db dml $db "end transaction"


if { ![exists_and_not_null return_url] } {
    set return_url [im_url_stub]/projects/view.tcl?[export_url_vars group_id]
}


if { [exists_and_not_null dp.im_projects.project_lead_id] } {
    # Need to add the project leader as well
    set return_url "/groups/member-add-3.tcl?[export_url_vars group_id return_url]&user_id_from_search=${dp.im_projects.project_lead_id}&role=administrator"
}

if { [exists_and_not_null dp_ug.user_groups.creation_user] } {
    # add the creating current user to the group
    ad_returnredirect "/groups/member-add-3.tcl?[export_url_vars group_id return_url]&user_id_from_search=$user_id&role=administrator"
} else {
    ad_returnredirect $return_url
}
