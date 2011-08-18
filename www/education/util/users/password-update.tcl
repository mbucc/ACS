#
# /www/education/util/users/password-update.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this lets an admin update a user's password
#

ad_page_variables {
    user_id
    {return_url ""}
}


set db [ns_db gethandle]

set exception_count 0 
set exception_text ""

if {[empty_string_p $user_id]} {
    incr exception_count 
    append exception_text "<li>You must provide an user identificaiton number in order to delete an user."
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

# gets the group_id.  If the user is not an admin of the group, it
# displays the appropriate error message and returns so that this code
# does not have to check the group_id to make sure it is valid

set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


# lets make sure the user is in this group

set selection [ns_db 0or1row $db "select distinct first_names, 
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
    append exception_text "<li>The user identification number provided was not valid.  Please select a valid id number."
} else {
    set_variables_after_query
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    # terminate execution of this thread (a goto!)
    return
}


if {[empty_string_p $return_url]} {
    set return_url "one.tcl?user_id=$user_id"
}


set return_string "
[ad_header "$group_name @ [ad_system_name]"]

<h2>Update Password</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" Administration] [list "" Users] "Update Password"]

<hr>
<blockquote>

<p>Type the new password. Type it again to Confirm, then click OK.</p>

<form method=POST action=\"password-update-2.tcl\">
  <table>
[export_form_vars user_id first_names last_name return_url]
    <tr>
      <th align=right>Name:</th>
      <td>$first_names $last_name</td>
    </tr>
    <tr>
      <th align=right>Email:</th>
      <td>$email</a>
    </tr>
    <tr>
      <th align=right>Url:</th>
      <td>[edu_maybe_display_text $url]</td>
    </tr>
      <th align=right>New password:</th>
      <td align=left><input type=password name=password_1 size=15></td>
    </tr>
    <tr>
      <th align=right>Confirm:</th>
      <td align=left><input type=password name=password_2 size=15></td>
    </tr>
    <tr>
      <td></td>
      <td><input type=submit value=\"OK\"></td>
  </table>
</form>

</blockquote>

[ad_footer]
"

ns_db releasehandle $db 

ns_return 200 text/html $return_string






