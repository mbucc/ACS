# 
# /www/education/class/admin/properties-edit-3.tcl
#
# by randyg@arsdigita.com, aillen@mit.edu
#
# This page actually updates the class_info table to reflect the changes in the
# properties of the class
#

ad_page_variables {
    class_name
    {term_id ""}
    {where_and_when ""}
    {start_date ""}
    {end_date ""}
    {public_p t}
    {grades_p t}
    {exams_p t}
    {final_exam_p t}
    {teams_p f}
    {description ""} 
    pretty_role_ta
    pretty_role_professor
    pretty_role_student    
    pretty_role_dropped
    pretty_role_plural_ta
    pretty_role_plural_professor
    pretty_role_plural_student
    pretty_role_plural_dropped
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]


#check the input
set exception_count 0
set exception_text ""

ns_db dml $db "begin transaction"

ns_db dml $db "update user_groups set group_name = [ns_dbquotevalue $class_name] where group_id = $class_id"

ns_db dml $db "update edu_class_info
                   set start_date  = '$start_date',
                       end_date = '$end_date',
	               term_id = $term_id,
	               description = [ns_dbquotevalue $description],
	               where_and_when = [ns_dbquotevalue $where_and_when],
	               public_p = '$public_p',
	               grades_p = '$grades_p',
	               teams_p = '$teams_p',
	               exams_p = '$exams_p',
	               final_exam_p = '$final_exam_p',
      	               last_modified = sysdate,
                       last_modifying_user = $user_id,
                       modified_ip_address = '[ns_conn peeraddr]'                       
                 where group_id = $class_id"

set role_list [database_to_tcl_list $db "select role from user_group_roles where role != 'administrator' and group_id=$class_id"]

foreach role $role_list {
    ns_db dml $db "update edu_role_pretty_role_map 
          set pretty_role=[ns_dbquotevalue [set [string tolower pretty_role_[join $role "_"]]]], 
              pretty_role_plural =  [ns_dbquotevalue [set pretty_role_plural_[string tolower [join $role "_"]]]] 
              where group_id=$class_id 
                and lower(role)=lower('$role')"
}

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect index.tcl










