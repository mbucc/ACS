#
# /www/education/subject/admin/user-search.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com
#
# this page allows the person to select a user to lead a class
#

ad_page_variables {
    email
    last_name
    {target_url class-add.tcl}
    {param_list ""}
    {browse_type ""}
}


# param_list should be any variables that need to be passed on
# to the next page.  These variables should have already been
# url encoded.  So, the calling page should have a line that looks like
# set param_list [ns_urlencode var1 var2 ...] and then
# [export_url_vars $param_list]

set db [ns_db gethandle]

if {[string compare [string tolower $browse_type] select_instructor] == 0} {
    set begin_header "Select an Instructor/Moderator for the Class"
    set nav_bar_value "Select Instructor"
    set instructions "To select a user as the instructor, please click on their name."
    } else {
    set begin_header "Site Wide Users Search Results"
    set nav_bar_value "Site Wide Users"
    set instructions "To view information about a user, simply click on their name."
}

set exception_count 0 
set exception_text ""

if { [empty_string_p $email] && [empty_string_p $last_name] } {
    incr exception_count
    append exception_text "<li>You need to search for a customer by either Last Name or Email\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    # terminate execution of this thread (a goto!)
    return
}

#lets strip the leading and trailing spaces off of the last_name and email
if {[info exists last_name]} {
    set bb last_name
    regexp {[ ]*(.*[^ ])} $last_name match last_name
}

if {[info exists email]} {
    regexp {[ ]*(.*[^ ])} $email match email
    set aa '$email'
}



### search by last_name and email
if { ![empty_string_p $last_name] && ![empty_string_p $email] } {
    set query_string "select distinct users.user_id, first_names, last_name, email from users, user_group_map
    where upper(last_name) like '%[DoubleApos [string toupper $last_name]]%'
    and upper(email) like '%[DoubleApos [string toupper $email]]%'
    and user_group_map.user_id = users.user_id
    order by lower(last_name), first_names"
    set title "Users whose last name contains '$last_name' and email contains '$email'"
}

## search by email
if { [empty_string_p $last_name] && ![empty_string_p $email] } {
    set query_string "select distinct users.user_id, first_names, last_name, email from users, user_group_map 
    where upper(email) like '%[DoubleApos [string toupper $email]]%'
    and user_group_map.user_id = users.user_id
    order by lower(last_name), first_names"
    set title "Users whose email contains '$email'"
}

## search by last_name
if { ![empty_string_p $last_name] && [empty_string_p $email] } {
    set query_string "select distinct users.user_id, first_names, last_name, email from users, user_group_map 
    where upper(last_name) like '%[DoubleApos [string toupper $last_name]]%'
    and user_group_map.user_id = users.user_id
    order by lower(last_name), first_names"
    set title "Users whose last name contains '$last_name'"
}

set selection [ns_db select $db $query_string]


set return_string "
[ad_header "Add a Class @ [ad_system_name]"]
<h2> $begin_header </h2>
$title
<br>
<br>

[ad_context_bar_ws [list "../" "Subjects"] [list "" "Subject Administration"] "Add a Class"]

<hr>
"

set text ""
set counter 0
while { [ns_db getrow $db $selection] } {

    set_variables_after_query
    incr counter
    append text "<li><a href=\"$target_url?user_id=$user_id&$param_list\">$last_name, $first_names ($email)</a>\n"
}


if { $counter > 0 } {

    append return_string "
    $title:
    <ul>
    $text
    <br><br>
    </ul>
    $instructions
    "
} else {
    append return_string "We found no matches to your query for $title, please check your information again\n"
}


append return_string "
<br>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string





