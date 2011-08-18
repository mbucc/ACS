#
# /www/education/class/admin/grade-policy-edit.tcl
#
# by aileen@mit.edu, randyg@arsdigita.com, February 2000
#
# this page allows the user to edit the way the grades are calculated
#


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Evaluate"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set return_string "
[ad_header "$class_name Grading Policy @ [ad_system_name]"]

<h2>Edit Grading Policy for $class_name</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Grading Policy"]

<hr>
<blockquote>
<b>All weights must add up to 100%. * denotes required fields</b>
<form method=post action=grade-policy-edit-2.tcl>
<table cellpadding=2>
<tr>
<th align=left>Grade Name*</th>
<th align=left>Weight*</th>
<th align=left>Comments</th>
</tr>
"

set selection [ns_db select $db "select * from edu_grades where class_id=$class_id"]

set grade_id_list ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "
    <tr>
    <td valign=top><input type=text size=30 value=\"$grade_name\" name=grade_name_$grade_id></td>
    <td valign=top><input type=text size=5 value=\"$weight\" name=weight_$grade_id> \%</td>
    <td>[edu_textarea comments_$grade_id $comments 40 3]</td>
    </tr>"

    lappend grade_id_list $grade_id
}

set count 1

while {$count<=5} {
    append return_string "
    <tr>
    <td valign=top><input type=text size=30 name=new_grade_name_$count></td>
    <td valign=top><input type=text size=5 name=new_weight_$count> \%</td>
    <td>[edu_textarea new_comments_$count "" 40 3]</td>
    </tr>"
    incr count
}

append return_string "
[export_form_vars grade_id_list]
[edu_empty_row]
<tr><td colspan=3><input type=submit value=Submit></td></tr>
</table>
</form>
</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string





