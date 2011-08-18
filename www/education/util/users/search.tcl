# 
# /www/education/util/users/user-search.tcl
# 
# by randyg@arsdigita.com, aileen@mit.edu January, 2000
#
# This file lists the users for a given class (group) that match the search criteria 
# and divides them by role.  In addition, it allows the caller to show
# only people with "emails beginning with" or "last name beginning with"
#


ad_page_variables {
    {email ""}
    {last_name ""}
    {target_url "user-info.tcl"}
    {type ""}
    {target_url_params ""}
    {section_id ""}
}



set db [ns_db gethandle]

set group_pretty_type [edu_get_group_pretty_type_from_url]

# right now, the proc above is only set up to recognize type 
# group and department and the proc must be changed if this page
# is to be used for URLs besides those.

if {[empty_string_p $group_pretty_type]} {
    ns_returnnotfound
    return
} else {

    if {[string compare $group_pretty_type class] == 0} {
	set id_list [edu_user_security_check $db]
    } else {
	# it is a department
	set id_list [edu_group_security_check $db edu_department]
    }
}


set user_id [lindex $id_list 0]
set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


if {[string compare $type section_leader] == 0} {
    set header_string "Select a Section Instructor"
    set end_string ""
    set nav_bar_value "Select Section Leader"
    set instructions "To select a user, simply click on their name."
    set var_name instructor_id
    set sql_restriction "and role <> '[edu_get_student_role_string]'"

} else {
    set header_string "$group_name Users"
    set end_string "<br><a href=\"add.tcl\">Add a User</a>"
    set nav_bar_value "Users"
    set instructions "To view information about a user, simply click on their name."
    set var_name user_id
    set sql_restriction ""
}


if {![empty_string_p $target_url_params]} {
    set middle_char &
    set target_url "$target_url?$target_url_params"
} else {
    set middle_char ?
}


set exception_count 0 
set exception_html ""

if { [empty_string_p $email] && [empty_string_p $last_name] } {
    incr exception_count
    append exception_html "<li>You need to search for a customer by either Last Name or Email\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_html
    # terminate execution of this thread (a goto!)
    return
}



#lets strip the leading and trailing spaces off of the last_name and email
regexp {[ ]*(.*[^ ])} $last_name match last_name
regexp {[ ]*(.*[^ ])} $email match email


set begin_query_string "select distinct users.user_id, first_names, last_name, email from users, user_group_map where user_group_map.group_id = $group_id and user_group_map.user_id = users.user_id"


if {![empty_string_p $section_id]} {
    append sql_restriction "and user_group_map.user_id not in (select user_id from user_group_map where group_id = $section_id and role = 'administrator')
}



### search by last_name and email
if { ![empty_string_p $last_name] && ![empty_string_p $email] } {
    set query_string "
          and upper(last_name) like '%[DoubleApos [string toupper $last_name]]%'
          and upper(email) like '%[DoubleApos [string toupper $email]]%'
          and user_group_map.user_id = users.user_id
          $sql_restriction
     order by last_name, first_names"
    set title "Users whose last name contains '$last_name' and email contains '$email'"
}

## search by email
if { [empty_string_p $last_name] && ![empty_string_p $email] } {
    set query_string "
          and upper(email) like '%[DoubleApos [string toupper $email]]%'
          and user_group_map.user_id = users.user_id
          $sql_restriction
     order by last_name, first_names"
    set title "Users whose email contains '$email'"
}

## search by last_name
if { ![empty_string_p $last_name] && [empty_string_p $email] } {
    set query_string "
          and upper(last_name) like '%[DoubleApos [string toupper $last_name]]%'
          and user_group_map.user_id = users.user_id
          $sql_restriction
     order by last_name, first_names"
    set title "Users whose last name contains '$last_name'"
}


append html "
[ad_header "Add a [capitalize $group_pretty_type] Member @ [ad_system_name]"]
<h2> $header_string </h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] $nav_bar_value"]

<hr>
<blockquote>
"

set counter 0

set selection [ns_db select $db "$begin_query_string $query_string"]

set text ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    if {$counter == 0} {
	append text "
	<table>
	<tr><td><B>Name</b></td><td><B>Email</b></td></tr>
	"
    }

    incr counter

    append text "
    <tr>
    <td><a href=\"$target_url${middle_char}${var_name}=$user_id\">$last_name, $first_names</a>
    </td>
    <td>
    $email
    </td>
    </tr>
    "
}


if { $counter > 0 } {
    append html "
    $title:
    <ul>
    $text
    </table>
    <br><br>
    </ul>
    $instructions
    "
} else {
    append html "
    We found no matches to your query for $title, 
    please check your information again \n
    "
}


append html "
<br>
$end_string
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $html






