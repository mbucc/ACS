#
# /www/eduction/class/admin/users/one.tcl
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

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Manage Users"]
if {$id_list == 0} {
    return
}

set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

# let's find out the role and name of the user so that we can decide
# whether or not to redirect.

set selection [ns_db select $db "select first_names, 
         last_name, 
         email, 
         map.role,
         pretty_role,
         url,
         portrait,
         portrait_thumbnail
    from users, 
         user_group_map map,
         edu_role_pretty_role_map role_map 
   where users.user_id = $authorized_user_id 
     and users.user_id = map.user_id 
     and map.group_id=$class_id
     and map.group_id = role_map.group_id
     and lower(map.role) = lower(role_map.role)"]

set count 0
set role_list [list]
set pretty_role_list [list]
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr count
    lappend role_list [string tolower $role]
    lappend pretty_role_list $pretty_role
}

if {$count == 0} {
    ad_return_complaint 1 "<li>The user identification number recieved by this page is not valid.  Please try accessing the page through a different method. $user_id $class_id"
    return
} 


# if the person that we are supposed to show is a student, lets redirect to 
# student_info.tcl

if {[lsearch $role_list [string tolower [edu_get_student_role_string]]] != -1 || [lsearch $role_list [string tolower [edu_get_dropped_role_string]]] != -1} {
    ad_returnredirect "student-info.tcl?student_id=$authorized_user_id"
    return
}


set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Information for $first_names $last_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" Users] "One User"]


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
select distinct mf.field_name, 
       field_value
  from user_group_member_field_map m,
       user_group_type_member_fields mf,
       user_group_map map
 where m.user_id=$authorized_user_id 
   and m.group_id=$class_id
   and lower(mf.field_name) = lower(m.field_name)
   and (mf.role is null or lower(mf.role) = lower(map.role))
   and map.user_id = m.user_id
   and map.group_id = m.group_id"]

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
<td>[join $pretty_role_list ", "]</td>
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

if {[ad_permission_p $db "" "" "Evaluate" $user_id $class_id]} {

    append return_string "
    <h3>Evaluations given by $first_names</h3>
    
    <ul>
    "

    # lets first get all of the assignment and exam evaluations
    
    set selection [ns_db select $db "select first_names || ' ' || last_name as student_name,
      grade,
      assignment_name,
      edu_assignments.assignment_id,
      users.user_id as student_id,
      evaluation_type
 from edu_student_evaluations eval,
      users,
      edu_assignments
where grader_id = $authorized_user_id
  and eval.class_id = $class_id
  and student_id = users.user_id
  and eval.task_id = edu_assignments.assignment_id(+)
order by evaluation_date"]

    set count 0

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	incr count
	
	append return_string "<li><a href=\"student-info.tcl?student_id=$student_id\">$student_name</a>, $grade on "
	
	if {[empty_string_p $assignment_name]} {
	    append return_string "$evaluation_type"
	} else {
	    append return_string "<a href=\"../assignment-info.tcl?assignment_id=$assignment_id\">$assignment_name</a>"
	}
    }
    
    
    # now lets see if they have given any team evaluations
    
    set selection [ns_db select $db "select team_name,
      grade,
      assignment_name,
      edu_assignments.assignment_id,
      edu_teams.team_id,
      evaluation_type
 from edu_student_evaluations eval,
      edu_assignments,
      edu_teams
where grader_id = $authorized_user_id
  and edu_teams.class_id = $class_id
  and eval.team_id = edu_teams.team_id
  and eval.task_id = edu_assignments.assignment_id(+)
order by evaluation_date"]


    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	incr count
	
	append return_string "<li><a href=\"../teams/one.tcl?team_id=$team_id\">$team_name</a>, $grade on "
	
	if {[empty_string_p $assignment_name]} {
	    append return_string "$evaluation_type"
	} else {
	    append return_string "<a href=\"../assignment-info.tcl?assignment_id=$assignment_id\">$assignment_name</a>"
	}
    }
    
    
    if {$count == 0} {
	append return_string "No Evaluations given"
    }

    append return_string "
    </ul>
    "
}


set n_spams_sent [database_to_tcl_string $db "select count(spam_id) from group_spam_history where sender_id = $authorized_user_id and group_id in (select unique group_id from user_groups where parent_group_id = $class_id)"]

if {$n_spams_sent > 0} {
    append return_string "
    <p>
    <li>$first_names has sent <a href=\"../spam-history.tcl?user_id=$authorized_user_id\">$n_spams_sent spams</a>"
}

append return_string " 

<p>
  <li><a href=\"info-edit.tcl?user_id=$authorized_user_id\">Edit user info</a>
  <li><a href=\"role-change.tcl?user_id=$authorized_user_id\">Edit user's roles</a></li>
  <li><a href=\"password-update.tcl?user_id=$authorized_user_id\">Update user's password</a></li>
  <li><a href=\"delete.tcl?user_id=$authorized_user_id\">Remove user</a></li>

</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string





