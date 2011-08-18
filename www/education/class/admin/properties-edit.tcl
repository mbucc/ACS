# 
# /www/education/class/admin/properties-edit.tcl
#
# by randyg@arsdigita.com, aillen@mit.edu
#
# This page displays the form so that the class admin can edit the properties of
# the class
#

# this does not require any variables to be passed in.

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set selection [ns_db 0or1row $db "select start_date,
	class_id,
	class_name,
	term_id,
	start_date,
	end_date,
	description,
	where_and_when,
	syllabus_id,
	lecture_notes_folder_id,
	handouts_folder_id,
	assignments_folder_id,
	public_p,
	grades_p,
	teams_p,
	exams_p,
	final_exam_p
   from edu_classes
  where class_id = $class_id"]

if {$selection == ""} {
    # this should never happen.
    ad_return_complaint 1 "<li>The group you are logged in as is not a class.  Please log out and log back in."
    return
} else {
    set_variables_after_query
}


set return_string "
[ad_header "Edit Class Properties"]

<h2>Edit Class Properties</h2>

[ad_context_bar_ws [list "../one.tcl" "$class_name"] [list "" "Administration"] "Edit Class Properties"]

<hr>
<blockquote>

<form method=post action=\"properties-edit-2.tcl\">

<table>
<tr><th align=right>Class Title
<td><input type=text size=60 name=class_name maxsize=100 value=\"$class_name\"> 
</tr>

<tr><th align=right>Term: 
<td>
[edu_term_select_widget $db term_id $term_id]
</tr>

<tr><th valign=top align=right>Meeting time and place: 
<br>(e.g. Lecture: TR10 (10-250) Recitation: WF10 (13-4101) or WF11 (13-4101))</th>
<td>[edu_textarea where_and_when $where_and_when 50 4]</td>
</tr>

<tr><th align=right>Date to Start Displaying Class Web Page: 
<td>[ad_dateentrywidget start_date $start_date]
</tr>

<tr><th align=right>Date to Stop Displaying Class Web Page: 
<td>[ad_dateentrywidget end_date $end_date]
</tr>

<tr><th align=right>Will the class web page and documents be open to the public?
</td><td>
"

if {[string compare $public_p t] == 0} {
    append return_string "<input type=radio name=public_p checked value=t>Yes &nbsp;<input type=radio name=public_p value=f>No"
} else {
    append return_string "<input type=radio name=public_p value=t>Yes &nbsp;<input type=radio name=public_p value=f checked>No"
}

append return_string "
</td></tr>
<tr><th align=right>Do students recieve grades?
</td><td>
"

if {[string compare $grades_p t] == 0} {
    append return_string "<input type=radio name=grades_p value=t checked>Yes &nbsp;<input type=radio name=grades_p value=f>No"
} else {
    append return_string "<input type=radio name=grades_p value=t>Yes &nbsp;<input type=radio name=grades_p value=f checked>No"
}

append return_string "
</td></tr>
<tr><th align=right>Will the class have teams?
</td><td>
"

if {[string compare $teams_p t] == 0} {
    append return_string "<input type=radio name=teams_p value=t checked>Yes &nbsp;<input type=radio name=teams_p value=f>No"
} else {
    append return_string "<input type=radio name=teams_p value=t>Yes &nbsp;<input type=radio name=teams_p value=f checked>No"
}

append return_string "
</td></tr>
<tr><th align=right>Will the class have exams?
</td><td>
"

if {[string compare $exams_p t] == 0} {
    append return_string "<input type=radio name=exams_p value=t checked>Yes &nbsp;<input type=radio name=exams_p value=f>No"
} else {
    append return_string "<input type=radio name=exams_p value=t>Yes &nbsp;<input type=radio name=exams_p value=f checked>No"
}

append return_string "
</td></tr>
<tr><th align=right>Will the class have a final exam?
</td><td>
"

if {[string compare $final_exam_p t] == 0} {
    append return_string "<input type=radio name=final_exam_p value=t checked>Yes &nbsp;<input type=radio name=final_exam_p value=f>No"
} else {
    append return_string "<input type=radio name=final_exam_p value=t>Yes &nbsp;<input type=radio name=final_exam_p value=f checked>No"
}

append return_string "
</td></tr>
<tr><th align=right>Class Description
<td>[edu_textarea description "$description"]
</tr>
<tr><td align=right valign=top colspan=2>

<table>
<tr>
<th align=right valign=top>Staff Titles:</th>
<td>

<table>
<tr>
<th>[ad_space]</th>
<th>Singular</th>
<th>Plural</th>
</tr>

"

set selection [ns_db select $db "select role, pretty_role, pretty_role_plural from edu_role_pretty_role_map where group_id=$class_id and role != 'administrator' order by sort_key"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "
    <tr>
    <th>[capitalize $role]</th>
    <td>
    <input type=text name=pretty_role_[string tolower [join $role "_"]] value=\"$pretty_role\">
    </td>
    <td>
    <input type=text name=pretty_role_plural_[string tolower [join $role "_"]] value=\"$pretty_role_plural\">
    </td>
    </tr>
    "
}
    

append return_string "
</table>
</td>
</tr>
</table>
<tr><td colspan=2 align=center><input type=submit value=\"Continue\"></td>
</tr>
</table>
</form>

</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string







