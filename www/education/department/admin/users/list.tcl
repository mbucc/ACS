# 
# /www/education/department/admin/users/list.tcl
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
    {target_url "one.tcl"}
    {target_url_params ""}
    {order_by "last_name, first_names, email"}
    {section_id ""}
}


set db [ns_db gethandle]


set id_list [edu_group_security_check $db edu_department "Manage Users"]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]



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
	set order_by "last_name, first_names, email"
    } else {
	set header "Emails $begin through $lastletter"
	set sql_suffix "and upper('$begin') < upper(email)
                    and '$end' > upper(email)
                    and users.user_id > 2"
	set order_by "email, last_name"
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
    set header_string "$department_name Users"
    set end_string "<a href=user-add.tcl>Add a User</a>"
    set nav_bar_value "Users"
}



set return_string "

[ad_header "Add a Department @ [ad_system_name]"]

<h2>$header_string - $header </h2>

[ad_context_bar_ws [list "/department/one.tcl?department_id=$department_id" "$department_name Home"] [list "" Administration] "$nav_bar_value"]


<hr>

<h3>Current Users</h3>

<blockquote>
"



# if there is a target url, make all users go to the same url
# otherwise, have them go to user-info


set selection [ns_db select $db "select distinct users.user_id, 
                       first_names, 
                       last_name,
                       role
                  from users, 
                       user_group_map    
                 where user_group_map.group_id = $department_id
                       and users.user_id = user_group_map.user_id 
                       $sql_suffix
                       
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
    append return_string "The are currently no users in this department $department_id"
} else {
    append return_string "<br><li><a href=\"../spam.tcl?who_to_spam=[ns_urlencode $role]\">Spam the [capitalize $role]s</a> (link does not yet work) \n"
}

append return_string "
</ul>

</blockquote>

[ad_footer]
"



ns_db releasehandle $db

ns_return 200 text/html $return_string





