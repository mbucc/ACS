#
# /www/education/util/users/add-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page displays the search results
#

ad_page_variables {
    {email ""}
    {last_name ""}
}


set db [ns_db gethandle]

set group_pretty_type [edu_get_group_pretty_type_from_url]

# right now, the proc above is only set up to recognize type 
# class and department and the proc must be changed if this page
# is to be used for URLs besides those.

if {[empty_string_p $group_pretty_type]} {
    ns_returnnotfound
    return
} else {

    if {[string compare $group_pretty_type class] == 0} {
	set id_list [edu_group_security_check $db edu_class "Manage Users"]
    } else {
	# it is a department
	set id_list [edu_group_security_check $db edu_department]
    }
}



# gets the group_id.  If the user is not an admin of the group, it
# displays the appropriate error message and returns so that this code
# does not have to check the group_id to make sure it is valid

set user_id [lindex $id_list 0]
set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


# either email or last_name must be not null

set exception_count 0 
set exception_text ""

if { [empty_string_p $email] && [empty_string_p $last_name] } {
    incr exception_count
    append exception_text "<li>You need to search for administrator by either Last Name or Email\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    # terminate execution of this thread (a goto!)
    return
}


set sql_suffix "and user_id not in (select user_id from user_group_map where group_id = $group_id)"

### search by last_name and email
if { ![empty_string_p $last_name] && ![empty_string_p $email] } {
    set query_string "select user_id as user_id_to_add, first_names, last_name, email from users 
    where upper(last_name) like '%[string toupper $last_name]%'
    and upper(email) like '%[string toupper $email]%' $sql_suffix"
    set title "Users whose last name contains $last_name and email contains $email:"
}

## search by email
if { [empty_string_p $last_name] && ![empty_string_p $email] } {
    set query_string "select user_id as user_id_to_add, first_names, last_name, email from users 
    where upper(last_name) like '%[string toupper $last_name]%'
    and upper(email) like '%[string toupper $email]%' $sql_suffix"
    set title "Users whose email contains $email:"
}

## search by last_name
if { ![empty_string_p $last_name] && [empty_string_p $email] } {
    set query_string "select user_id as user_id_to_add, first_names, last_name, email from users 
    where upper(last_name) like '%[string toupper $last_name]%'
    and upper(email) like '%[string toupper $email]%' $sql_suffix"
    set title "Users whose last name contains $last_name:"
}



set return_string "
[ad_header "$group_name @ [ad_system_name]"]

<h2>Add a user for $group_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "Add a User"]

<hr>
"

set selection [ns_db select $db $query_string]

set text ""
set counter 0
while { [ns_db getrow $db $selection] } {

    set_variables_after_query
    incr counter
    append text "<li><a href=\"add-3.tcl?[export_url_vars user_id_to_add last_name first_names]\">$last_name, $first_names ($email)</a>\n"
}


if { $counter > 0 } {
    append return_string "
    $title
    <ul>
    $text
    </ul>
    To make the community memeber a group member, click on the name above.
    "
} else {
    append return_string "We found no matches to your query, please check your information again\n"
}


append return_string "
<br>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string


