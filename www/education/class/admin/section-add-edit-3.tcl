#
# /www/education/class/admin/section-add-edit-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows a user to add information about a section
# (e.g. a recitation or tutorial)
#

ad_page_variables {
    {instructor_id ""}
    section_id
    section_name
    section_time
    section_place
}

# if it is an add, we require section_id

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]
set user_id [lindex $id_list 0]


if {[database_to_tcl_string $db "select count(group_id) from user_groups where group_id = $section_id"] > 0} {
    # this is an edit so do an update
    
    ns_db dml $db "begin transaction"

    ns_db dml $db "update edu_section_info 
                   set section_place = [ns_dbquotevalue $section_place],
                       section_time = [ns_dbquotevalue $section_time]
                 where group_id = $section_id"

    ns_db dml $db "update user_groups set group_name = [ns_dbquotevalue $section_name] where group_id = $section_id"

    ns_db dml $db "end transaction"
                       

} else {
    # this is an add so do an insert
    
    set var_set [ns_set new]
    
    ns_set put $var_set class_id $class_id
    ns_set put $var_set section_place $QQsection_place
    ns_set put $var_set section_time $QQsection_time
    
    ad_user_group_add $db edu_section $QQsection_name t f closed f $var_set $section_id

    ns_db dml $db "update user_groups set parent_group_id = $class_id where group_id = $section_id"

    if {![empty_string_p $instructor_id]} {
	# now, lets add the instructor as a member of the group	
	ad_user_group_user_add $db $instructor_id administrator $section_id 
    }

}

ns_db releasehandle $db

ad_returnredirect "section-info.tcl?section_id=$section_id"

