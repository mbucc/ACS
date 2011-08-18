#
# /www/education/department/admin/users/one.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page displays information about the users.  If the user had a role
# of 'student' for the given group then it redirects to student-info.tcl
#

ad_page_variables {
    user_id
}


set authorized_user_id $user_id

set db [ns_db gethandle]

# gets the department_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


# let's find out the role and name of the user so that we can decide
# whether or not to redirect.

set selection [ns_db select $db "select first_names, 
         last_name, 
         email, 
         map.role,
         url,
         portrait,
         portrait_thumbnail
    from users, 
         user_group_map map
   where users.user_id = $authorized_user_id 
     and users.user_id = map.user_id 
     and map.group_id=$department_id"]


set count 0
set role_list [list]
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr count
    lappend role_list [capitalize $role]
}

if {$count == 0} {
    ad_return_complaint 1 "<li>The user identification number recieved by this page is not valid.  Please try accessing the page through a different method. $user_id $department_id"
    return
} 


# if the person that we are supposed to show is a student, lets redirect to 
# student_info.tcl

if {[lsearch $role_list [string tolower [edu_get_student_role_string]]] != -1 || [lsearch $role_list [string tolower [edu_get_dropped_role_string]]] != -1} {
    ad_returnredirect "student-info.tcl?student_id=$authorized_user_id"
    return
}


append return_string "
[ad_header "$department_name @ [ad_system_name]"]

<h2>Information for $first_names $last_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl?department_id=$department_id" "$department_name Home"] [list "../" "Administration"] [list "" Users] "One User"]


<hr>
<blockquote>
<table>
<tr>
<td>

<table>
<tr><th align=right>Email:</th>
<td><a href=\"mailto:$email\">$email</a></td>
</tr>
<tr><th align=right>URL:</th>
<td> 
"

if {![empty_string_p $url]} {
    append return_string "<a href=\"$url\">$url</a>"
} else {
    append return_string "None"
}

append return_string "
</td>
</tr>
"

set selection [ns_db select $db "
select field_name, field_value from user_group_member_field_map m
where m.user_id=$authorized_user_id 
and m.group_id=$department_id"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    if {![empty_string_p $field_value]} {
	append return_string "
	<tr><th align=right>$field_name:</th>
	<td>$field_value</td>
	</tr>"    
    }
}
 

append return_string "
<tr><th align=right>User Role:</th> 
<td>[join $role_list ", "]</td>
</tr>
</table>


</td>
<td>
"

if {![empty_string_p $portrait_thumbnail]} {
    append return_string "
    <a href=\"/shared/portrait.tcl?user_id=$authorized_user_id\"><img width=125 src=\"/shared/portrait-thumbnail-bits.tcl?user_id=$authorized_user_id\"></a>"
} elseif {![empty_string_p $portrait]} {
    append return_string "
    <a href=\"/shared/portrait.tcl?user_id=$authorized_user_id\"><img width=125 src=\"/shared/portrait-bits.tcl?user_id=$authorized_user_id\"></a>"
}

append return_string "
</td>
</tr>
</table>

"

set n_spams_sent [database_to_tcl_string $db "select count(spam_id) 
      from group_spam_history 
     where sender_id = $authorized_user_id 
       and group_id in (select unique group_id 
                        from user_groups 
                       where parent_group_id = $department_id)"]

if {$n_spams_sent > 0} {
    append return_string "
    <p>
    <li>$first_names has sent <a href=\"../spam-history.tcl?user_id=$authorized_user_id\">$n_spams_sent spams</a>"
}


# lets get the list of classes that this person is associated with

set selection [ns_db select $db "select class_id, 
           term_name,
           class_name, 
           pretty_role
      from edu_classes,
           edu_terms,
           (select pretty_role, map.group_id
               from user_group_map map,
                    edu_role_pretty_role_map role_map
              where lower(role_map.role) = lower(map.role)
                and role_map.group_id = map.group_id
                and map.user_id = $authorized_user_id) groups
     where edu_classes.term_id = edu_terms.term_id(+)
       and groups.group_id = edu_classes.class_id
  order by lower(class_name), edu_classes.end_date, edu_terms.end_date"]
     


set count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if {$count == 0} {
	append return_string "<h3>Classes</h3><ul>"
    }
    append return_string "<li><a href=\"/education/util/group-login.tcl?group_id=$class_id&group_type=edu_class&return_url=[ns_urlencode [edu_url]/class/one.tcl]\"> $class_name </a>"
    if {![empty_string_p $term_name]} {
	append return_string "[ad_space] ($term_name)"
    }
    append return_string " - $pretty_role\n"
    incr count
}

if {$count > 0} {
    append return_string "</ul>"
}


append return_string " 
<p>
<li><a href=\"role-change.tcl?user_id=$authorized_user_id\">Edit user's roles</a></li>
<li><a href=\"password-update.tcl?user_id=$authorized_user_id\">Update user's password</a></li>
<li><a href=\"delete.tcl?user_id=$authorized_user_id\">Remove user</a></li>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string





