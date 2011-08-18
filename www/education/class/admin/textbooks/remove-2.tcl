#
# /www/education/class/admin/textbooks/remove-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page removes the book from the class to textbook mapping table 
# and so is removing the book from the class
#

ad_page_variables {
    textbook_id
}

if {[empty_string_p $textbook_id]} {
    ad_return_complaint 1 "<li>You must include a textbook to remove."
    return
}

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]

ns_db dml $db "delete from edu_classes_to_textbooks_map where class_id=$class_id and textbook_id=$textbook_id
"

ns_db releasehandle $db

ad_returnredirect ""
