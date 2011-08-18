# 
# /www/education/class/admin/users/user-list.tcl
# 
# by randyg@arsdigita.com, aileen@mit.edu January, 2000
#
# This file lists all of the users for a given class (group) and 
# divides them by role.  In addition, it allows the caller to show
# only people with "emails beginning with" or "last name beginning with"
#


ad_page_variables {
    begin
    end
    header_string
    browse_type
    lastletter
    {type ""}
    {target_url ""}
    {target_url_params ""}
    {order_by "last_name, first_names, email"}
    {section_id ""}
}


set db [ns_db gethandle]


set id_list [edu_group_security_check $db edu_class "Manage Users"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]



if { ([string compare $begin a] == 0 || [string compare $begin A] == 0) && ([string compare $end z] == 0 || [string compare $end Z] == 0) } {
    set header All
    set spam_links_p t
    set sql_suffix "and users.user_id > 2"
    set order_by "last_name, first_names, email"
    set no_one_found ""
} else {
    set no_one_found "matching your criteria."
    set spam_links_p f

    #This code assumes that the variable End is the correct case!!!
    if {[string compare $browse_type lastname] == 0} {
	set header "Last Names $begin through $lastletter"
	set sql_suffix "and upper('$begin') < upper(last_name)
                    and '$end' > upper(last_name)
                       and users.user_id > 2"
	set order_by "lower(last_name), lower(first_names), lower(email)"
    } else {
	set header "Emails $begin through $lastletter"
	set sql_suffix "and upper('$begin') < upper(email)
                    and '$end' > upper(email)
                    and users.user_id > 2"
	set order_by "lower(email), lower(last_name), lower(first_names)"
    }
}


set export_vars [export_url_vars begin end browse_type lastletter]

set count 0

if {![empty_string_p $target_url_params]} {
    set params [join $param_list "&"]
    append target_url "?$params"
    set middle_char &
} else {
    set middle_char ?
}


if {[string compare $type section_leader] == 0} {
    set header_string "Select a Section Instructor"
    set end_string ""
    set nav_bar_value "Add a Section"
} else {
    set header_string "$class_name Users"
    set end_string "<a href=user-add.tcl>Add a User</a>"
    set nav_bar_value "Users"
}


set return_string "
[ad_header "Add a Class @ [ad_system_name]"]

<h2>$header_string - $header </h2>

[ad_context_bar_ws [list "[edu_url]class/one.tcl" "$class_name Home"] [list "../" Administration] "$nav_bar_value"]


<hr>

<h3>Current Users</h3>

<blockquote>
"



# if there is a target url, make all users go to the same url
# otherwise, have them go to user-info

set spam_links t
set variable_name user_id
set sql_restriction ""
if {[empty_string_p $target_url]} {
    set target_url one.tcl
}

if {[string compare $type section_leader] == 0} {
    if {![empty_string_p $section_id]} {
	set sql_restriction "and user_group_map.user_id not in (select user_id from user_group_map where group_id = $section_id and role = 'administrator')"
    }
    set variable_name instructor_id
    set spam_links f
    
    set role_list [list Administrator [edu_get_professor_role_string] [edu_get_ta_role_string]]
} else {
    set temp_role_list [edu_get_class_roles_to_actions_map]
    set role_list [list]
    foreach role $temp_role_list {
	lappend role_list [lindex $role 0]
    }
    # we have to do the lines above and not the line below because we want
    # the roles to sort correctly
    # set role_list [database_to_tcl_list $db "select distinct lower(role) from user_group_roles where group_id = $class_id"]
}



foreach role $role_list {
    
    set selection [ns_db select $db "select distinct users.user_id, 
                       first_names, 
                       last_name,
                       email
                  from users, 
                       user_group_map    
                 where user_group_map.group_id = $class_id
                       and users.user_id = user_group_map.user_id 
                       and lower(role) = lower('$role')
                       $sql_suffix
	               $sql_restriction
              order by $order_by"]

    if {[string compare [string tolower $role] dropped] == 0} {
	set pretty_role "[capitalize $role]"
    } else {
	set pretty_role "[capitalize $role]s"
    }

    append return_string "<h3>$pretty_role</h3><ul>"
    
    set counter 0
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if {$counter == 0} {
	    append return_string "<table>"
	}
	incr counter
	append return_string "
	<tr><td><a href=\"${target_url}${middle_char}${variable_name}=$user_id\">$last_name, $first_names</a></td> <td>$email</td></tr>\n"
    }
    
    if {$counter == 0} {
	append return_string "The are currently no $pretty_role in this class $no_one_found"
    } elseif {[string compare $spam_links t] == 0} {
	append return_string "</table>"

	if {[string compare $spam_links_p t] == 0} {
	    append return_string "<br><li><a href=\"../spam.tcl?who_to_spam=[ns_urlencode $role]\">Spam the $pretty_role</a>"
	}
    }

    append return_string "</ul>\n"
}
   
append return_string "
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string






