#
# /www/education/class/admin/task-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page updates the information about the given task
#

ad_page_variables {
    task_id
    task_type
    task_name
    {return_url ""}
    {grade_id ""}
    {description ""}
    {weight ""}
    {ColValue.due%5fdate.day ""}
    {ColValue.due%5fdate.month ""}
    {ColValue.due%5fdate.year ""}
    online_p
    requires_grade_p
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


# check the user input first

set exception_text ""
set exception_count 0

if {[empty_string_p $task_name]} {
    append exception_text "<li>You must provide a name for this task."
    incr exception_count
}


# lets make sure that the passed in task belongs to this class

if {[database_to_tcl_string $db "select count(task_id) from edu_student_tasks where task_id = $task_id and class_id = $class_id"] == 0} {
    incr exception_count
    append exception_text "<li>The task you are trying to edit does not belong to this class."
}


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
} elseif {[database_to_tcl_string $db "select round(sysdate) - to_date('$due_date','YYYY-MM-DD') from dual"] > 1} {
    incr exception_count
    append exception_text "<li>The due date must be in the future."
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}


if {![info exists return_url] || [empty_string_p $return_url]} {
    set return_url ""
}


###########################################
#                                         #
# Permissions and Input have been checked #
# set up the tasks update           #
#                                         #
###########################################



set task_sql "update edu_student_tasks
           set assigned_by = $user_id,
               task_name = [ns_dbquotevalue $task_name],
               description = [ns_dbquotevalue $description],
               last_modified = sysdate,
               due_date = '$due_date',
               weight = [ns_dbquotevalue $weight],
               grade_id='$grade_id',
               online_p = '$online_p',
               requires_grade_p = '$requires_grade_p'
         where task_id = $task_id"

if {[catch { ns_db dml $db "begin transaction"
ns_db dml $db $task_sql 
ns_db dml $db "end transaction" } errmsg] } {
    # insert failed; let's see if it was because of duplicate submission
    ns_log Error "[edu_url]class/admin/task-edit-2.tcl choked:  $errmsg"
    ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}

ns_db releasehandle $db

# the updates went as planned so redirect
ad_returnredirect $return_url



