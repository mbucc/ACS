#
# /www/education/class/admin/grades-view.tcl
#
# by aileen@mit.edu, randyg@arsdigita.com, February 2000
#
# this page shows information about the particular grade item
#


ad_page_variables {
    grade_id
    {show_comments f}
}

set_the_usual_form_variables

set db_handles [edu_get_two_db_handles]
set db [lindex $db_handles 0]
set db_sub [lindex $db_handles 1]

set id_list [edu_group_security_check $db edu_class "Evaluate"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set grade_name [database_to_tcl_string $db "select grade_name from edu_grades where grade_id=$grade_id"]

set return_string "
[ad_header "$class_name Grades @ [ad_system_name]"]

<h2>$class_name $grade_name Grades</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Grades"]

<hr>
<blockquote>
"

if {$show_comments=="f"} {
    set show_comments "f"
    append comment_string "
    <a href=grades-view.tcl?grade_id=$grade_id&show_comments=t>Show Comments</a>"
} else {
    set show_comments "t"
    append comment_string "
    <a href=grades-view.tcl?grade_id=$grade_id&show_comments=f>Hide Comments</a>"
}

set header_row [list "<th align=left>Name</th>"]
set task_id_list ""

set selection [ns_db select $db "
select task_type, task_id, task_name 
from edu_student_tasks 
where class_id=$class_id 
and grade_id=$grade_id 
order by task_name"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    set str  "<th align=left><a href="

    set type [string trimright $task_type s]

    append str $type
    append str "-info.tcl?"
    append str $type
    append str "_id=$task_id>$task_name</a></th>"
    lappend header_row $str
    lappend task_id_list $task_id
}

set selection [ns_db select $db "
select a.task_name, a.task_id, se.student_id, u.first_names, 
       u.last_name, se.grade, se.comments
from edu_student_tasks a, edu_student_evaluations se, 
     users u
where a.class_id = $class_id
and a.task_id = se.task_id
and a.grade_id = $grade_id
and se.student_id=u.user_id
order by last_name, a.task_name"]

# either there is an entry in evaluations with task_id=a.task_id
# and student_id=u.user_id or such entry does not exist

set header_done 0
set old_student_id ""
set data_list ""
set task_index -1
set old_task_id ""
set row_list ""

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    # new row of data
    if {$student_id!=$old_student_id} {
	if {$old_student_id!=""} {	    
	    while {$task_index!=[expr [llength $task_id_list] - 1]} {
		lappend row_list "<td valign=top>Not graded</td>"
		incr task_index
	    }
	    lappend data_list $row_list
	}
	   
	set old_student_id $student_id
	set row_list [list "<td valign=top><a href=\"users/student-info.tcl?student_id=$student_id\">$last_name, $first_names</a></td>"]
	set task_index -1
    } 

    incr task_index

    # determine whether the student has a grade for this task
    while {[lindex $task_id_list $task_index]!=$task_id} {
	incr task_index
	lappend row_list "<td valign=top>Not graded</td>"
    } 

    lappend row_list "<td valign=top>$grade [ec_decode $show_comments "t" " - $comments" ""]</td>"
    set old_task_id $task_id
    incr count
}

while {$task_index!=[expr [llength $task_id_list] - 1]} {
    lappend row_list "<td valign=top>Not graded</td>"
    incr task_index
}

if {$count} {
    lappend data_list $row_list
    
    append return_string "
    $comment_string
    <p>
    <table cellpadding=2>
    <tr>
    "
    
    foreach header $header_row {
	append return_string "
	$header"
    }
    
    append return_string "
    </tr>
    "
    
    foreach row $data_list {
	append return_string "<tr>"
	
	foreach column $row {
	    append return_string "$column"
	}
	
	append return_string "</tr>"
    }

    append return_string "</table>"
} else {
    append return_string "
    <p>There are no grades to show for this grade group. Please check your grade group settings for assignments, exams, and projects."
}

append return_string "   
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string

