#
# /www/education/department/admin/users/index.tcl
# 
# by randyg@arsdigita.com, aileen@mit.edu January, 2000
#
# This file lists all of the users for a given department (group) and 
# divides them by role.  In addition, it allows the caller to show
# only people with "emails beginning with" or "last name beginning with"
#

ad_page_variables {
    {target_url one.tcl}
    {type ""}
    {target_url_params ""}
}


#This is a list of all the users in a given company and provides
#links to different functions regarding those users

set db [ns_db gethandle]

# gets the department_id.  If the user is not an admin of the department, it
# displays the appropriate error message and returns so that this code
# does not have to check the department_id to make sure it is valid

set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]

set sql_restriction ""

if {![empty_string_p $target_url]} {
    set header_string "$department_name Users"
    set end_string "<a href=\"add.tcl\">Add a User</a>"	
} else {
    set target_url "one.tcl"
    set header_string "$department_name Users"
    set end_string "<a href=\"add.tcl\">Add a User</a>"
}



set return_string "
[ad_header "$department_name @ [ad_system_name]"]


<h2>$header_string</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$department_name Home"] [list "../" "Administration"] Users]

<hr>
<blockquote>

"

set threshhold 75

#see if there are more than $threshhold users
#if so, give search options
#if not, list all of the users

if {[database_to_tcl_string $db "select count(distinct user_id) from user_group_map where group_id = $department_id"] < $threshhold } {

    append return_string "
    <h3>Current Users</h3>
    <blockquote>
    "

    set selection [ns_db select $db "select distinct users.user_id, 
                       first_names, 
                       last_name,
                       role
                  from users, 
                       user_group_map    
                 where user_group_map.group_id = $department_id
                       and users.user_id = user_group_map.user_id 
              order by lower(role), lower(last_name), lower(first_names)"]


    set counter 0
    set previous_role member
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if {[string compare [string tolower $role] $previous_role]} {
	    if {$counter > 0} {
		append return_string "</ul>"
	    }
	    append return_string "<h3>[capitalize $role]</h3><ul>"
	}
	append return_string "
	<li><a href=\"$target_url?$target_url_params&user_id=$user_id\">$last_name, $first_names</a><br>\n"
	incr counter
    }
    
    if {$counter == 0} {
	append return_string "The are currently no users in this department."
    } else {
	append return_string ""
	#<br><li><a href=\"../spam.tcl?who_to_spam=[ns_urlencode $role]\">Spam the [capitalize $role]s</a> (link does not yet work) \n"
    }

    append return_string "</ul>"

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

    <p>

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

</ul>
</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string










