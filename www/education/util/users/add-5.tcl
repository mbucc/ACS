#
# /www/education/util/users/add-5.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page inserts the user into the group
#

ad_page_variables {
    user_id_to_add
    role
    first_names
    last_name
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

# we do not need to worry about whether or not the user is already in
# the group because the proc just changes the role is that is the case

ad_user_group_user_add $db $user_id_to_add $role $group_id

ns_db releasehandle $db

ns_return 200 text/html "
[ad_header "Add User"]

<h2> Confirm Add User for $group_name</h2>

[ad_context_bar_ws_or_index [list "../../" "$group_name Home"] [list "../" "Administration"] [list "" Users] "User Added"]

<hr>
<blockquote>
$first_names $last_name has been added to $group_name.
<br>
<br>
You may now
<a href=\"one.tcl?user_id=$user_id_to_add\">

View User Information</a> for $first_names $last_name

or

<a href=\"\">Return to the Users Page</a>
</blockquote>

[ad_footer]
"



