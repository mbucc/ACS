#
# /www/education/class/admin/projects/instance-add-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows users to confirm their addition project instances. 
#

ad_page_variables {
    project_id
    project_instance_name 
    url 
    description
    {max_body_count ""}
    {min_body_count ""}
    team_id_or_new_or_none
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


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


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


if {[empty_string_p $project_instance_name]} {
    incr exception_count
    append exception_text "<li>You must provide a name for this project."
}

if { ![regexp {^[0-9]*$} $max_body_count] || \
	![regexp {^[0-9]*$} $min_body_count] }  {
    incr exception_count
    append exception_text "<li>Student numbers must be either integers or left blank.\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set project_instance_id [database_to_tcl_string $db "select edu_project_instance_id_seq.nextval from dual"]


if {[string compare $url "http://"] == 0 || [empty_string_p $url]} {
    set url_to_show ""
    set url ""
} else {
    set url_to_show $url
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


set return_string "
[ad_header "One Project @ [ad_system_name]"]

<h2>Add a Project Instance</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "All Projects"] "Add Project Instance"]

<hr>
for $project_name
<blockquote>

<form method=post action=\"instance-add-3.tcl\">

[export_form_vars project_id project_instance_id project_instance_name url description team_id team_name max_body_count min_body_count]

Please confirm the information that you have entered.

<table>

<tr>
<th align=right>
Name:
</td>
<td>
$project_instance_name
</td>

<tr>
<th align=right>
URL:
</td>
<td>
$url_to_show
</td>

<tr>
<th align=right>Number of students:</th>
<td>
Min:&nbsp;$pretty_min_body_count
&nbsp;&nbsp;Max:&nbsp;$pretty_max_body_count
</td>

<tr>
<th align=right>
Team Assignment:
</th>
<td>$team_name $team_extra_text</td>

<tr>
<th align=right valign=top>
Description:
</td>
<td>
$description
</td>

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






