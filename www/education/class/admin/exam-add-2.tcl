#
# /www/education/class/admin/exam-add.tcl
#
# by aileen@mit.edu, randyg@arsdigita.com, January, 2000
#
# this page calls edu_file_upload_widget which outputs shared code from
# /file-storage/upload-new.tcl. file_id is set by the caller of the widget
#

ad_page_variables {
    {ColValue.date%5fadministered.day ""}
    {ColValue.date%5fadministered.month ""}
    {ColValue.date%5fadministered.year ""}
    exam_name
    {comments ""}
    {weight ""}
    {grade_id ""}
    {online_p f}
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

if {[empty_string_p $exam_name]} {
    append exception_text "<li>You must include a name for this exam."
    incr exception_count
}


# put together date_administered, and do error checking

set form [ns_getform]

# ns_dbformvalue $form due_date date due_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.date%5fadministered.day and stick the new value into the $form
# ns_set.

set "ColValue.date%5fadministered.day" [string trimleft [set ColValue.date%5fadministered.day] "0"]
ns_set update $form "ColValue.date%5fadministered.day" [set ColValue.date%5fadministered.day]

if [catch  { ns_dbformvalue $form date_administered date date_administered} errmsg ] {
    incr exception_count
    append exception_text "<li>The date was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.date%5fadministered.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
} elseif {[database_to_tcl_string $db "select round(sysdate) - to_date('$date_administered','YYYY-MM-DD') from dual"] > 1} {
    incr exception_count
    append exception_text "<li>The exam date must be in the future."
}



if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set default_read ""
set default_write [edu_get_ta_role_string]

# generate this here so that we avoid a double click error
set exam_id [database_to_tcl_string $db "select edu_task_sequence.nextval from dual"]


if {[empty_string_p $date_administered]} {
    set date_string None
} else {
    set date_string [util_AnsiDatetoPrettyDate $date_administered]
}


set return_string "
[ad_header "Add an Exam @ [ad_system_name]"]

<h2>Add an Exam</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Add an Exam"]

<hr>
<blockquote>

<form method=post action=\"task-add-3.tcl\">
[export_entire_form]
<input type=hidden name=\"task_type\" value=\"exam\">
<input type=hidden name=\"task_id\" value=\"$exam_id\">
<input type=hidden name=\"task_name\" value=\"$exam_name\">
<input type=hidden name=\"electronic_submission_p\" value=\"$online_p\">


<table BORDER=0>

<tr>
<th valign=top align=right>Exam Name: </td>
<td valign=top>
$exam_name
</td>
</tr>

<tr>
<th valign=top align=right>Comments: </td>
<td valign=top>
[edu_maybe_display_text $comments]
</td>
</tr>

<tr>
<th valign=top align=right>Exam Date: </td>
<td valign=top>
$date_string
</td>
</tr>

<tr>
<th valign=top align=right> Fraction of Exam Grade: </td>
<td valign=top>
"

if {[empty_string_p $weight]} {
    append return_string "N/A"
} else {
    append return_string "$weight \%"
}

append return_string "
</td>
</tr>
"

if {![empty_string_p $grade_id]} {
    set selection [ns_db 0or1row $db "select grade_name, weight from edu_grades where grade_id=$grade_id"]
} else {
    set selection ""
}

if {$selection!=""} {
    set_variables_after_query
} else {
    set grade_name ""
    set weight ""
}

append return_string "
<tr><th valign=top align=right>Grade Policy Group</th>
<td>[edu_maybe_display_text $grade_name] [ec_decode $weight "" "" "- $weight"]\%</td>
<tr>
<th valign=top align=right> 
Administered online?
</td>
<td valign=top>
[util_PrettyBoolean $online_p]
</font>
</td>
</tr>

<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Add Exam\">
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
