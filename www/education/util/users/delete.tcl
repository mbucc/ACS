#
# /www/education/util/users/delete.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this class allows the admin to remove the user from the 
# user_group_map table
#
# Note that deleting a user does not actually delete all of the user's
# stuff.  It only deletes the person from the mapping table.  So, when
# you list all items turned in, etc. you should still check and make
# sure that the student is still part of the class

ad_page_variables {
    user_id
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
	set id_list [edu_group_security_check $db edu_class "Manage Users"]
    } else {
	# it is a department
	set id_list [edu_group_security_check $db edu_department]
    }
}

# gets the group_id.  If the user is not an admin of the group, it
# displays the appropriate error message and returns so that this code
# does not have to check the group_id to make sure it is valid

set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


set exception_count 0 
set exception_text ""

if {[empty_string_p $user_id]} {
    incr exception_count 
    append exception_text "<li>You must provide an user identificaiton number in order to delete an user."
}


set selection [ns_db 0or1row $db "select distinct users.user_id,
         first_names, 
         last_name, 
         email,
         url
    from users,
         user_group_map map 
   where map.user_id=$user_id 
     and map.user_id = users.user_id
     and group_id = $group_id"]

if { $selection == "" } {
    incr exception_count
    append exception_text "<li>The user identificaiton number provided was not valid.  Please select a valid id number."
} else {
    set_variables_after_query
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    # terminate execution of this thread (a goto!)
    return
}


ns_db releasehandle $db

ns_return 200 text/html "
[ad_header "$group_name @ [ad_system_name]"]

<h2> Confirm User Removal</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "Delete User"]

<hr>
<ul>
<li>Click OK to remove <u>$first_names $last_name</u> as an authorized user from $group_name.</li>
</ul>
<form method=post action=\"delete-2.tcl\">

[export_form_vars user_id first_names last_name]

<center><input type=submit value=\"OK\"></center>
</form>

[ad_footer]
"

