#
# /www/education/class/admin/users/students-view.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page should be used when we want to give a list of all of
# the students in a class so that the user can select from the
# list and then move on.
#


ad_page_variables {
    {target_url "student-info.tcl"}
    {view_type all}
    {target_url_vars ""}
    {order_by "last_name"}
    {section_id ""}
    {project_instance_name ""}
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]



set student_roles [database_to_tcl_list $db "select pretty_role, pretty_role_plural from edu_role_pretty_role_map where lower(role) = lower('[edu_get_student_role_string]') and group_id = $class_id"]

set student_pretty_role [lindex $student_roles 0]
set student_pretty_role_plural [lindex $student_roles 1]

set exception_count 0
set exception_text ""

if {[string compare $view_type section] == 0} {
    if {[empty_string_p $section_id]} {
	incr exception_count
	append exception_text "<li>In order to restrict by section, you must provide a section identification number."
    } else {
	# lets make sure the section provided is part of this class
	set section_name [database_to_tcl_string_or_null $db "select section_name from edu_sections where section_id = $section_id and class_id = $class_id"]
	if {[empty_string_p $section_name]} {
	    incr exception_count
	    append exception_text "<li>The section identification number you have provided is not a section of $class_name"
	} else {
	    # this means that section name was defined above
	    set title "All $student_pretty_role_plural"
	    set sub_title "in $class_name not in $section_name"
	    set header "View All $student_pretty_role_plural not in $section_name"
	    set sql_restriction "and map.user_id not in (select user_id from user_group_map where group_id = $section_id)"
	}
    }
} elseif {[string compare $view_type project] == 0} {
    set title "Select a $student_pretty_role"
    set header "Select a $student_pretty_role for a project"
    set sql_restriction ""
    if {![empty_string_p $project_instance_name]} {
	set sub_title "for $project_instance_name"
    } else {
	set sub_title ""
    }
} else {
    # this is the base case where we want to show all students
    set title "All $student_pretty_role_plural"
    set header "View All $student_pretty_role_plural"
    set sql_restriction ""
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}



set return_string "
[ad_header "$header"]

<h2>$title</h2>
"

if {[info exists sub_title] && ![empty_string_p $sub_title]} {
    append return_string "<p>$sub_title<p>"
}

append return_string "
[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] "$student_pretty_role_plural"]

<hr>

<blockquote>
"

set export_string [export_url_vars target_url view_type target_url_vars section_id]


if {[string compare $order_by "last_name desc"] == 0} {
    set header "
    <td><b><a href=\"students-view.tcl?$export_string&order_by=last_name\">Name</b></td>
    <td><b><a href=\"students-view.tcl?$export_string&order_by=email\">Email</b></td>"
    
    set order_by "lower(last_name) desc"
} elseif {[string compare $order_by "email"] == 0} {
    set order_by "lower(email)"
    set ordering "lower(email) desc"
    set header "
    <td><b><a href=\"students-view.tcl?$export_string&order_by=last_name\">Name</b></td>
    <td><b><a href=\"students-view.tcl?$export_string&order_by=[ns_urlencode $ordering]\">Email</b></td>"
    
} elseif {[string compare $order_by "email desc"] == 0} {
    
    set order_by "lower(email) desc"
    set header "
    <td><b><a href=\"students-view.tcl?$export_string&order_by=last_name\">Name</b></td>
    <td><b><a href=\"students-view.tcl?$export_string&order_by=email\">Email</b></td>"
    
} else {
    
    set order_by "lower(last_name)"

    set ordering "last_name desc"
    set header "
    <td><b><a href=\"students-view.tcl?$export_string&order_by=[ns_urlencode $ordering]\">Name</b></td>
    <td><b><a href=\"students-view.tcl?$export_string&order_by=email\">Email</b></td>"
}

# this query makes the assumption that no students have both the role
# of "Student" and "Dropped" at the same time.  If they do, their
# name will appear twice on the list and will be pretty stupid

set selection [ns_db select $db "select 
                 distinct map.user_id as student_id,
                 last_name,
                 first_names,
                 email,
                 role
            from user_group_map map,
                 users
           where users.user_id = map.user_id
             and (lower(map.role) = lower('[edu_get_student_role_string]')
                  or lower(map.role) = lower('[edu_get_dropped_role_string]'))
             $sql_restriction
             and map.group_id = $class_id
        order by $order_by"]


set count 0


set dropped_role_string [string tolower [edu_get_dropped_role_string]]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    if {!$count} {
	append return_string "
	<table cellpadding=2>
	<tr>
	$header
	<td>[ad_space 1]</td>
	</tr>
	"
    }

    append return_string "
    <tr>
    <td><a href=\"$target_url?student_id=$student_id&$target_url_vars\">$last_name, $first_names</a></td>
    <td>$email</td>
    <td>[ad_space 1]
    "
    
    if {[string compare [string tolower $role] $dropped_role_string] == 0} {
	append return_string "<font color=red>Dropped</font>"
    }

    append return_string "</td></tr>"
   
    incr count
}

if {$count} {
    append return_string "
    </table>"
} else {
    append return_string "
    <p>There are currently no $student_pretty_role_plural registered in the system</p>"
}


# if this is a project, we want to give the person the option of
# assigning the student at a later date.  We set the student_id = 0
# signifying that we have not selected a user.  

if {[string compare $view_type project] == 0} {
    append return_string "
    <p>
    <a href=\"$target_url?$target_url_vars&student_id=0\">Assign a [string tolower $student_pretty_role] at a later time</a>
    "
} elseif {[string compare $view_type section] != 0} {
    append return_string "
    <p>
    <a href=\"add.tcl\">Add a User $view_type</a>"
}

append return_string "
</blockquote>
[ad_footer]"



ns_db releasehandle $db

ns_return 200 text/html $return_string



