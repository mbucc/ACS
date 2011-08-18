#
# /www/education/class/admin/teams/evaluation-add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page inserts the evaluation information for the team
# into the database
#

ad_page_variables {
    team_id
    evaluation_type
    grade
    comments
    show_team_p
    evaluation_id
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set grader_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

ns_db dml $db "
insert into edu_student_evaluations
(evaluation_id, grader_id, class_id, team_id, evaluation_type, 
 grade, comments, show_student_p)
values
($evaluation_id, $grader_id, $class_id, $team_id, [ns_dbquotevalue $evaluation_type],
 [ns_dbquotevalue $grade], [ns_dbquotevalue $comments], [ns_dbquotevalue $show_team_p])"

ns_db releasehandle $db

ad_returnredirect "one.tcl?team_id=$team_id"
 

