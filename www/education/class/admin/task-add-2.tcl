#
# /www/education/class/admin/task-add-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this file displays a confirmation page for the user to review the
# information they have just entered.
# 

ad_page_variables {
    task_name
    {description ""}
    task_type
    {ColValue.due%5fdate.day ""}
    {ColValue.due%5fdate.month ""}
    {ColValue.due%5fdate.year ""}
    {weight ""}
    {grade_id ""}
    {requires_grade_p f}
    {electronic_submission_p f}
}    


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

# check the input

set exception_text ""
set exception_count 0


# put together due_date, and do error checking

set form [ns_getform]

# ns_dbformvalue $form due_date date due_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.due%5fdate.day and stick the new value into the $form
# ns_set.

set "ColValue.due%5fdate.day" [string trimleft [set ColValue.due%5fdate.day] "0"]
ns_set update $form "ColValue.due%5fdate.day" [set ColValue.due%5fdate.day]

if [catch  { ns_dbformvalue $form due_date date due_date} errmsg ] {
    incr exception_count
    append exception_text "<li>The date was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.due%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
} 


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


# generate the task_id here so that we avoid a double click error
set task_id [database_to_tcl_string $db "select edu_task_sequence.nextval from dual"]


if {[empty_string_p $due_date]} {
    set date_string None
} else {
    set date_string [util_AnsiDatetoPrettyDate $due_date]
}

    

if {[string compare $task_type project] == 0} {
    set header "Add a Project"
} elseif {[string compare $task_type assignment] == 0} {
    set header "Add an Assignment"
} else {
    set header "Add Exam"
}



set return_string "
[ad_header "$header @ [ad_system_name]"]

<h2>$header</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "$header"]

<hr>
<blockquote>

Please review the information you have entered.  You will be given an
opportunity to upload an associated file once you add the $task_type.

<form method=post action=\"task-add-3.tcl\">
[export_form_vars task_name description due_date weight grade_id requires_grade_p electronic_submission_p task_id task_type]

<table BORDER=0>

<tr>
<th valign=top align=right> [capitalize $task_type] Name: </td>
<td valign=top>
$task_name
</td>
</tr>

<tr>
<th valign=top align=right> Description: </td>
<td valign=top>
[edu_maybe_display_text $description]
</td>
</tr>

<tr>
<th valign=top align=right> Due Date: </td>
<td valign=top>
$date_string
</td>
</tr>

<tr>
<th valign=top align=right>Will this $task_type<br>be graded? </td>
<td valign=top>
[util_PrettyBoolean $requires_grade_p]
</td>
</tr>

<tr>
<th valign=top align=right> Fraction of [capitalize $task_type] Grade: </td>
<td valign=top>
"

if {[empty_string_p $weight]} {
    append return_string "N/A"
} else {
    append return_string "$weight"
}

append return_string "
</td>
</tr>
"

if {[empty_string_p $grade_id]} {
    set selection ""
} else {
    set selection [ns_db 0or1row $db "select grade_name, weight from edu_grades where grade_id=$grade_id"]
}

if {$selection!=""} {
    set_variables_after_query
    set weight [expr round([expr $weight*100])]
} else {
    set grade_name ""
    set weight ""
}


append return_string "
<tr><th valign=top align=right>Grde Policy Group</th>
<td>[edu_maybe_display_text $grade_name] [ec_decode $weight "" "" "- $weight"]</td>
<tr>
<th valign=top align=right> 
Online submission?
</th>
<td valign=top>
[util_PrettyBoolean $electronic_submission_p]
</font>
</td>
</tr>
<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Add [capitalize $task_type]\">
</td>
</tr>
</table>

</form>

<p>

</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string

