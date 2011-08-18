#
# /www/education/class/admin/projects/instance-add-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows users to confirm their addition project instances. 
#

ad_page_variables {
    project_id
    project_type
    {project_instance_name ""}
    {url ""}
    {description ""}
    {max_body_count ""}
    {min_body_count ""}
    {team_id_or_new_or_none ""}
    {student_id ""}
}

# if view_type = user then student_id must be not null.  If student_id
# is 0 then the user has decided to select the student at a later point
# in time.
# if the view_type = team then the team_id_or_new_or_none must be not
# null

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {[string compare $project_type user] && [empty_string_p $student_id]} {
    incr exception_count
    append exception_text "<li>In order to have a user project, you must provide a user."
}


# Generate pretty strings for body counts.
# We could use ad_page_variables defaulting (if it actually worked)
# but then we'd be passing the pretty strings, yuk.
if [empty_string_p $max_body_count] {
    set pretty_max_body_count "unspecified"
} else {
    set pretty_max_body_count $max_body_count
}
if [empty_string_p $min_body_count] {
    set pretty_min_body_count "unspecified"
} else {
    set pretty_min_body_count $min_body_count
}



set exception_count 0
set exception_text ""

if {[empty_string_p $project_id]} {
    incr exception_count
    append exception_text "<li>You must provide a project identification number"
} else {

 set selection [ns_db 0or1row $db "select project_name
        from edu_projects
       where project_id = $project_id
         and class_id = $class_id"]
    
    if {$selection == ""} {
	ad_return_complaint 1 "There are no projects in this class corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
	return
    } else {
	set_variables_after_query
    }
}


set project_instance_id [database_to_tcl_string $db "select edu_project_instance_id_seq.nextval from dual"]


if {[string compare $url "http://"] == 0 || [empty_string_p $url]} {
    set url_to_show ""
    set url ""
} else {
    set url_to_show $url
}



if {[string compare $project_type team] == 0} {
    if { ![regexp {^[0-9]*$} $max_body_count] || \
	    ![regexp {^[0-9]*$} $min_body_count] }  {
	incr exception_count
	append exception_text "<li>User numbers must be either integers or left blank.\n"
    } elseif {![empty_string_p $max_body_count] && ![empty_string_p $min_body_count]} {
	if {$min_body_count > $max_body_count} {
	    incr exception_count
	    append exception_text "<li>The minimum number of users on the project cannot be larger than the maximum number."
	}
    }
    
    if {[empty_string_p $project_instance_name]} {
	incr exception_count
	append exception_text "<li>You must provide a name for this project."
    }

    # Generate team_id and team_name from form input
    set team_extra_text {}
    switch $team_id_or_new_or_none {
	none {
	    set team_name "None, will assign later"
	    set team_id ""
	}
	new {
	    set team_name "$project_instance_name Team"
	    set team_extra_text (new)
	    set team_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]
	}
	default {
	    # We got a team_id, should be an integer.
	    set team_id $team_id_or_new_or_none
	    validate_integer team_id $team_id
	    if { [catch { set team_name [database_to_tcl_string $db "select team_name
	    from edu_teams
	    where team_id = $team_id"] } errMsg] } {
		# ouch!  Oracle choked.
		ad_return_error "Team not found." "We could not find the team.  Here is what Oracle had to say:
		<blockquote>
		$errMsg
		</blockquote>
		"
	    }
	}
    }
    
    # display the team information
    set display_string "
    <tr>
    <th align=right>Number of students:</th>
    <td>
    Min: [ad_space] $pretty_min_body_count
    [ad_space] Max: [ad_space] $pretty_max_body_count
    </td>
    </tr>
    
    <tr>
    <th align=right>
    Team Assignment:
    </th>
    <td>$team_name $team_extra_text</td>
    </tr>
    "
} else {
    set user_name [database_to_tcl_string_or_null $db "select first_names || ' ' || last_name from users where user_id = $student_id"]

    if {[empty_string_p $user_name]} {
	set user_name "None, will assign later."
    }

    if {[empty_string_p $project_instance_name]} {
	set project_instance_name $user_name
    }

    set display_string "
    <tr>
    <th align=right>
    User:
    </th>
    <td>$user_name</td>
    </tr>
    "
}
    
if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}




set return_string "
[ad_header "One Project @ [ad_system_name]"]

<h2>Add a Project Instance</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "All Projects"] "Add Project Instance"]

<hr>
for $project_name
<blockquote>

<form method=post action=\"instance-add-4.tcl\">

[export_form_vars project_id project_instance_id project_instance_name url description team_id team_name max_body_count min_body_count project_type student_id]

Please confirm the information that you have entered.

<table>

<tr>
<th align=right>
Name:
</td>
<td>
$project_instance_name
</td>
</tr>

<tr>
<th align=right>
URL:
</td>
<td>
[edu_maybe_display_text $url_to_show]
</td>
</tr>

$display_string

<tr>
<th align=right valign=top>
Description:
</td>
<td>
[edu_maybe_display_text $description]
</td>
</tr>

<tr>
<td colspan=2 align=center>
<input type=submit value=\"Add Project\">
</td>
</tr>

</table>
</form>

</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string






