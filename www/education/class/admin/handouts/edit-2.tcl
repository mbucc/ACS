#
# /www/education/class/admin/handouts/edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this update the handouts table with the new information
#

ad_page_variables {
    handout_id
    file_title
    {ColValue.distribution%5fdate.year ""}
    {ColValue.distribution%5fdate.day ""}
    {ColValue.distribution%5fdate.month ""}
    {version_description ""}
    {return_url ""}
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_text ""
set exception_count 0

if {[empty_string_p $handout_id]} {
    append exception_text "<li>You must provide a way to identify your handout."
    incr exception_count
}

# put together due_date, and do error checking

set form [ns_getform]

# ns_dbformvalue $form due_date date due_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.due%5fdate.day and stick the new value into the $form
# ns_set.

set "ColValue.distribution%5fdate.day" [string trimleft [set ColValue.distribution%5fdate.day] "0"]
ns_set update $form "ColValue.distribution%5fdate.day" [set ColValue.distribution%5fdate.day]

if [catch  { ns_dbformvalue $form distribution_date date distribution_date} errmsg ] {
    incr exception_count
    append exception_text "<li>The date was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.distribution%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
} 


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}


set version_id [database_to_tcl_string_or_null $db "select version_id
  from edu_handouts,
       (select * from fs_versions_latest 
        where ad_general_permissions.user_has_row_permission_p($user_id, 'write', version_id, 'FS_VERSIONS') = 't') ver
 where class_id = $class_id
   and handout_id = $handout_id
   and edu_handouts.file_id = ver.file_id"]


if {[empty_string_p $version_id]} {
    ad_return_complaint 1 "<li>The handout you are trying to view is not part of this class and therefore you are not authorized to view it at this time."
    return
} else {
    set_variables_after_query
}


#
# lets update the rows
#

ns_db dml $db "begin transaction"

ns_db dml $db "update edu_handouts
set handout_name = '$QQfile_title',
    distribution_date = '$distribution_date'
where handout_id = $handout_id
  and class_id = $class_id"

ns_db dml $db "update fs_versions set version_description = '$QQversion_description' where version_id = $version_id"

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect $return_url