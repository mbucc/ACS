#
# /www/education/util/users/delete-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this class allows the admin to remove the user from the 
# user_group_map table
#
#
# Note that deleting a user does not actually delete all of the user's
# stuff.  It only deletes the person from the mapping table.  So, when
# you list all items turned in, etc. you should still check and make
# sure that the student is still part of the class
#

ad_page_variables {
    user_id
    first_names
    last_name
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



if {[empty_string_p $user_id]} {
    ad_return_complaint 1 "<li>You must provide an user identificaiton number in order to delete an user."
    return
}


# now, lets delete the user.  It does not matter if the user is a memeber
# of the group or not because the delete has the same outcome either way
# we want to delete the person from the group and from all of the teams
# and sections the user was in.

ns_db dml $db "delete from user_group_map 
       where user_id = $user_id 
         and (group_id = $group_id 
              or group_id in (select group_id
                              from user_groups 
                              where parent_group_id = $group_id))"



ns_db releasehandle $db 

ns_return 200 text/html "
[ad_header "Delete User"]


<h2> User Deleted from $group_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "User Deleted"]

<hr>
<blockquote>
$first_names $last_name has been removed from $group_name.
<br>
<br>
You may now
<a href=\"\">return to the users page</a>.
</blockquote>

[ad_footer]
"


