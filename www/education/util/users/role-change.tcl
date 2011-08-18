#
# /www/education/util/users/role-change.tcl
#
# randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to change the role of the given user
#

ad_page_variables {
    user_id
    {return_url ""}
}
    

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select first_names, last_name, email from users where users.user_id = $user_id"]

if {$selection == ""} {
    ad_return_complaint 1 "Invalid User ID" "The user identification number recieved by this page is not valid.  Please try accessing the page through a different method."
    return
} else {
    set_variables_after_query
}

set group_pretty_type [edu_get_group_pretty_type_from_url]

# right now, the proc above is only set up to recognize type 
# group and department and the proc must be changed if this page
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

set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


set return_string "
[ad_header "$group_name @ [ad_system_name]"]

<h2>Change User's Role</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "Change User's Role"]

<hr>

<blockquote>

User name: $first_names $last_name

<br>

User email: $email

<form method=get action=\"role-change-2.tcl\">

[export_form_vars return_url user_id]

[edu_group_user_role_select_widget $db role $group_id $user_id]

<p>

<input type=submit value=\"Change Role\">

</form>
</blockquote>

[ad_footer]
"

ns_return 200 text/html $return_string

