# 
# /www/education/class/admin/users/index.tcl
# 
# by randyg@arsdigita.com, aileen@mit.edu January, 2000
#
# This file lists all of the users for a given class (group) and 
# divides them by role.  In addition, it allows the caller to show
# only people with "emails beginning with" or "last name beginning with"
#

ad_page_variables {
    {target_url ""}
    {type ""}
    {target_url_params ""}
    {section_id ""}
}


#This is a list of all the users in a given company and provides
#links to different functions regarding those users

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set sql_restriction ""

if {![empty_string_p $target_url]} {
    if {[string compare $type section_leader] == 0} {
	set header_string "Select a Section Instructor"
	set end_string ""
    } else {
	set header_string "$class_name Users"
	set end_string "<a href=\"add.tcl\">Add a User</a>"	
    }
} else {
    set target_url "one.tcl"
    set header_string "$class_name Users"
    set end_string "<a href=\"add.tcl\">Add a User</a>"
}



set return_string "
[ad_header "$class_name @ [ad_system_name]"]


<h2>$header_string</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] Users]

<hr>
<blockquote>
"

set threshhold 75

#see if there are more than $threshhold users
#if so, give search options
#if not, list all of the users

if {[database_to_tcl_string $db "select count(distinct user_id) from user_group_map where group_id = $class_id"] < $threshhold } {

    append return_string "
    <h3>Current Users</h3>
    <blockquote>
    "

    # if there is a target url, make all users go to the same url
    # otherwise, have them go to one.tcl

    set spam_links t
    set variable_name user_id
    set sql_restriction ""
    if {[empty_string_p $target_url]} {
	set target_url one.tcl
    }

    if {[string compare $type section_leader] == 0} {
	    if {![empty_string_p $section_id]} {
		set sql_restriction "and user_group_map.user_id not in (select user_id from user_group_map where group_id = $section_id and lower(role) = 'administrator')"
	    }
	    set variable_name instructor_id
	    set spam_links f

	    set role_list_restriction "and (lower(roles.role) = lower('[edu_get_professor_role_string]') or lower(roles.role) = lower('[edu_get_ta_role_string]'))"
    } else {
	set role_list_restriction ""
    }

	set role_list [database_to_tcl_list_list $db "select 
                   roles.role, 
                   pretty_role_plural
              from user_group_roles roles,
                   edu_role_pretty_role_map map
             where roles.group_id = $class_id 
               and roles.group_id = map.group_id
               and lower(roles.role) = lower(map.role) $role_list_restriction
          order by sort_key"]


    foreach role $role_list {

	set selection [ns_db select $db "select distinct users.user_id, 
                       first_names, 
                       last_name
                  from users, 
                       user_group_map    
                 where user_group_map.group_id = $class_id
                       and users.user_id = user_group_map.user_id 
                       and lower(role) = lower('[lindex $role 0]')
	               $sql_restriction
              order by lower(last_name), lower(first_names)"]

	append return_string "<h3>[lindex $role 1]</h3><ul>"

	set counter 0
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    incr counter
	    append return_string "
	    <li><a href=\"$target_url?$target_url_params&$variable_name=$user_id\">$last_name, $first_names</a><br>\n"
	}
	
	if {$counter == 0} {
	    append return_string "The are currently no [lindex $role 1] in this class"
	} elseif {[string compare $spam_links t] == 0} {
	    append return_string "<br><li><a href=\"../spam.tcl?who_to_spam=[ns_urlencode [list [lindex $role 0]]]\">Spam the [lindex $role 1]</a>"
	}


	append return_string "</ul>\n"
    }
    append return_string "</blockquote>"

} else {

    set url_string [export_url_vars type section_id target_url target_url_params header_string]

    append return_string "
    <li>Browse by last name : 
    <a href=\"list.tcl?begin=A&end=H&lastletter=G&browse_type=lastname&$url_string\">A - G</a> |
    <a href=\"list.tcl?begin=H&end=N&lastletter=M&browse_type=lastname&$url_string\">H - M</a> |
    <a href=\"list.tcl?begin=N&end=T&lastletter=S&browse_type=lastname&$url_string\">N - S</a> |
    <a href=\"list.tcl?begin=T&end=z&lastletter=Z&browse_type=lastname&$url_string\">T - Z</a> 
    <br><br>
    <li>Browse by email address : 
    <a href=\"list.tcl?begin=A&end=H&lastletter=G&browse_type=email&$url_string\">A - G</a> |
    <a href=\"list.tcl?begin=H&end=N&lastletter=M&browse_type=email&$url_string\">H - M</a> |
    <a href=\"list.tcl?begin=N&end=T&lastletter=S&browse_type=email&$url_string\">N - S</a> |
    <a href=\"list.tcl?begin=T&end=z&lastletter=Z&browse_type=email&$url_string\">T - Z</a> 
    <br><br>
    <li><a href=\"list.tcl?begin=A&end=z&lastletter=Z&browse_type=all&$url_string\">Browse All Users</a>
    <Br>
    <br>
    <form method=post action=\"search.tcl\">
    [export_form_vars type section_id target_url target_url_params header_string]
    <li>Search:
    <br>
    <table>
    <tr>
    <td align=right>
    By last name: 
    </td>
    <td><input type=text name=last_name>
    </td>
    <tr>
    <td align=right>
    By email: 
    </td>
    <td>
    <input type=text name=email>
    </td>
    </tr>
    <tr>
    <td colspan=2><input type=submit value=\"Search\">
    </td>
    </tr>
    </table>
    </form>
    "
}

append return_string "
<br>

$end_string

</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string








