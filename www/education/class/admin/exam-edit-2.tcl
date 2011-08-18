#
# /www/education/class/admin/exam-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the user to edit the information about the exam.
# it actually performs the update on the database

ad_page_variables {
    exam_id
    exam_name
    {ColValue.date%5fadministered.day ""}
    {ColValue.date%5fadministered.month ""}
    {ColValue.date%5fadministered.year ""}
    {comments ""}
    {weight ""} 
    {grade_id ""}
    {online_p f}
    {return_url ""}
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


# check the user input first

set exception_text ""
set exception_count 0


if {[empty_string_p $exam_name]} {
    append exception_text "<li>You must provide a name for this exam."
    incr exception_count
}


# lets make sure that the passed in exam belongs to this class

if {[database_to_tcl_string $db "select count(exam_id) from edu_exams where exam_id = $exam_id and class_id = $class_id"] == 0} {
    incr exception_count
    append exception_text "<li>The exam you are trying to edit does not belong to this class."
}


# put together date_administered, and do error checking

set form [ns_getform]

# ns_dbformvalue $form date_administered date date_administered will give an error
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
#    incr exception_count
#    append exception_text "<li>The exam date must be in the future."
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}



###########################################
#                                         #
# Permissions and Input have been checked #
# set up the exams update                 #
#                                         #
###########################################


if {![empty_string_p $grade_id]} {
    set grade_sql "grade_id=$grade_id,"
} else {
    set grade_sql ""
}

if {![empty_string_p $weight]} {
    set weight_sql "weight=$weight,"
} else {
    set weight_sql ""
}

set exam_sql "update edu_exams
           set teacher_id = $user_id,
               exam_name = '$QQexam_name',
               comments = '$QQcomments',
               last_modified = sysdate,
               date_administered = '$date_administered',
               $weight_sql
               $grade_sql
               online_p = '$online_p'
         where exam_id = $exam_id"

if {[catch { ns_db dml $db $exam_sql } errmsg] } {
    # insert failed; we know it is not a duplicate error because this is an update
    ns_log Error "[edu_url]class/admin/exam-edit-2.tcl choked:  $errmsg"
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













