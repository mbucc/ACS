#
# /www/education/class/syllabus.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page serves the syllabus for the given class
#

set db [ns_db gethandle]


set id_list [edu_user_security_check $db]
set class_id [lindex $id_list 1]

# this does not expect any arguemnts

if {[database_to_tcl_string $db "select count(class_id) from edu_current_classes where class_id = $class_id and syllabus is not null"] == 0} {
    ad_return_complaint 1 "<li>The syllabus you have requested either does not exist or access to it has been restricted by the course administrator."
    return
}

set file_type [database_to_tcl_string $db "select syllabus_file_type from edu_current_classes where class_id = $class_id"]


ReturnHeaders $file_type

ns_ora write_clob $db "select syllabus from edu_classes where class_id = $class_id"

