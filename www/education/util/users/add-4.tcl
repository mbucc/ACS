#
# /www/education/util/users/add-4.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This is the confirmation page before adding a user with the
# selected role to the group
#

ad_page_variables {
    first_names
    last_name
    user_id_to_add
    role
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

ns_db releasehandle $db

set exception_count 0 
set exception_text ""


if { [empty_string_p $first_names] } {
    incr exception_count
    append exception_text "<li>You need to supply the first name\n"
}

if { [empty_string_p $last_name] } {
    incr exception_count
    append exception_text "<li>You need to supply the last name\n"
}

if { [empty_string_p $role] } {
    incr exception_count
    append exception_text "<li>You need to supply a role for the new user\n"
}



if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    # terminate execution of this thread (a goto!)
    return
}


ns_return 200 text/html "
[ad_header "Add User"]

<h2> Confirm Add User for $group_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "Add a User"]

<hr>
<blockquote>
<li><u> $first_names $last_name</u> will be added as a user for $group_name as a [capitalize $role]
<p>

<form method=post action=\"add-5.tcl\">

[export_form_vars user_id_to_add role first_names last_name]

<center><input type=submit value=\"Add User\"></center>
</form>

</blockquote>

[ad_footer]
"

