#
# /www/education/util/users/add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page allows the admin to select a role for the new user
#

ad_page_variables {
    first_names
    last_name
    user_id_to_add
}


set group_pretty_type [edu_get_group_pretty_type_from_url]

# right now, the proc above is only set up to recognize type 
# group and department and the proc must be changed if this page
# is to be used for URLs besides those.

if {[empty_string_p $group_pretty_type]} {
    ns_returnnotfound
    return
} else {

    set db [ns_db gethandle]

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


set exception_text ""
set exception_count 0

set list_to_check [list [list user_id_to_add "user id"] [list first_names "first name"] [list last_name "last name"]]

foreach item $list_to_check {
    if {[empty_string_p [set [lindex $item 0]]]} {
	incr exception_count
	append exception_text "<li>You must provide the user's [lindex $item 1]\n"
    }
}

if { ![info exists user_id_to_add] || [empty_string_p $user_id_to_add] } {
    incr exception_count
    append exception_text "<li>You need to supply the user identification number\n"
} else {
    if {[ad_user_group_member $db $group_id $user_id_to_add] && $exception_count == 0} {
	incr exception_count
	append exception_text "<li>User $first_names $last_name is already an user for $group_name."
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set return_string "
[ad_header "Add User"]

<h2> Add User for $group_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "Add a User"]

<hr>

<blockquote>

Roles for $first_names $last_name

<form method=post action=\"add-4.tcl\">

[export_form_vars first_names last_name user_id_to_add]

[edu_group_user_role_select_widget $db role $group_id $user_id_to_add]

<p>

<input type=submit value=\"Select Role\">

</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string

