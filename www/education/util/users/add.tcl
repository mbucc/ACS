#
# /www/education/util/users/add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to input information about the user
# they want to add to the group
#

set group_pretty_type [edu_get_group_pretty_type_from_url]

# right now, the proc above is only set up to recognize type 
# class and department and the proc must be changed if this page
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

ns_return 200 text/html "
[ad_header "$group_name @ [ad_system_name]"]

<h2>Add a New User</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "Add a User"]

<hr>

<blockquote>

<form method=get action=\"add-2.tcl\">
  Search through all registered [ad_system_name] users for someone to add:
  <table>
  <tr><th align=right>by Email Address <td><input type=text maxlength=100 size=30 name=email><BR>
  <tr><th align=right>by Last Name <td><input type=text maxlength=100 size=30 name=last_name><BR>
  <tr><td colspan=2 align=center><input type=submit value=\"Search For a User\"></td></tr>
  </table>
  </form>
  <br>

  <br>

<form method=get action=\"add-new.tcl\">
Or, input a new user into the system.
  <table>
    <tr>
      <th align=right>New user's email address:</th>
      <td><input type=text name=email size=30></td>
    <tr>
    <tr>
      <th align=right>First name:</th>
      <td><input type=text name=first_names size=20></td>
    </tr>
    <tr>
      <th align=right>Last name:</th>
      <td><input type=text name=last_name size=25></td>
    </tr>
    <tr>
      <th align=right>Personal Home Page URL:  
      <td><input type=text name=user_url size=50 value=\"http://\"></td>
    </tr>
    <tr>
      <td align=center colspan=2><input type=submit name=action value=Continue></td>
    </tr>
  </table>
</form>

</blockquote>

[ad_footer]
"


