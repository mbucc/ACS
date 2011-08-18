#
# /www/education/class/admin/textbooks/add-to-class.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# associates an existing textbook to a class
#

ad_page_variables {
    textbook_id
    {comments ""}
    {required_p f}
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set class_id [lindex $id_list 1]

# make sure this association does not already exist

if {[database_to_tcl_string $db "select count(textbook_id) from edu_classes_to_textbooks_map where textbook_id=$textbook_id and class_id=$class_id"]==0} {

    ns_db dml $db "insert into edu_classes_to_textbooks_map
    (class_id, textbook_id, comments, required_p)
    values
    ($class_id, $textbook_id, '$QQcomments', '$required_p')
    "

}

ns_db releasehandle $db

ad_returnredirect ""
