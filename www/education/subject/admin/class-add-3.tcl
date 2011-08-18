#
# /www/education/subject/admin/class-add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this page inserts the class into the database as a member of
# this subject
#



ad_page_variables {
    group_name
    group_id
    term_id
    subject_id
    instructor_id
    start_date
    end_date
    {where_and_when ""}
    {public_p t}
    {grades_p t}
    {exams_p t}
    {final_exam_p t}
    {description ""}
    {teams_p f}
}




#check the input
set exception_count 0
set exception_text ""


set variables_to_check [list [list group_name "Class Title"] [list grades_p "Grades"] [list exams_p "Exams"] [list final_exam_p "Final Exam"] [list term_id "Term"] [list group_id "Group Identification Number"] [list start_date "Start Date"] [list end_date "End Date"]]

foreach var $variables_to_check {
    if {[empty_string_p [set [lindex $var 0]]]} {
	incr exception_count
	append exception_text "<li>You forgot to provide a value for the [lindex $var 1]"
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}



set db [ns_db gethandle]

set user_id [edu_subject_admin_security_check $db $subject_id]


#lets check and make sure that it is not a double click
if {[database_to_tcl_string $db "select count(group_id) from user_groups where group_id = $group_id"] > 0} {
    ad_returnredirect "index.tcl?subject_id=$subject_id"
    return
}



set term_name [database_to_tcl_string $db "select term_name from edu_terms where term_id = $term_id"]


# we want to add a folder in the file system for the class and
# within that folder we want to create a problem sets, lecture notes,
# and handouts folder



# we get IDs for class_folder, assignments_folder, lecture_notes_folder, 
# handouts_folder and exams_folder...these are file_id and version_id and
# we build a list to do the inserts

# the class folder name has to be first because it is the parent of the rest
# of the folders

# we also build the sql update clause at the same time...the folder_name_list
# is a list of lists corresponding to the folder name and a list of related columns

set folder_name_list [list [list "$group_name Class Folder - $term_name"] [list "Assignments" assignments_folder_id] [list "Lecture Notes" lecture_notes_folder_id] [list "Handouts" handouts_folder_id] [list "Exams" exams_folder_id] [list "Projects" projects_folder_id]]

set folder_id_list [list]
set sql_update_statment [list]
set folder_count 0

while {[llength $folder_id_list] < [llength $folder_name_list]} {
    set id_list [database_to_tcl_list_list $db "select fs_file_id_seq.nextval as a, fs_version_id_seq.nextval as b from dual"]
    lappend folder_id_list "[list [lindex [lindex $folder_name_list $folder_count] 0] [lindex [lindex $id_list 0] 0] [lindex [lindex $id_list 0] 1]]"

    if {[llength [lindex $folder_name_list $folder_count]] > 1} {
	lappend sql_update_statment "[lindex [lindex $folder_name_list $folder_count] 1] = [lindex [lindex $id_list 0] 0]"
    }

    incr folder_count
}


# the order of this is as follows:
# 1. stuff all of the edu_class_info variables into an ns_set
# 2. create the class
# 3. create the roles for the class
# 4. create the four folders for the class
# 5. place pointers to the folders into the edu_class_info table

# we have to create the folders after we create the class because the
# folders reference the class and doing it the other way around would
# cause an error.


ns_db dml $db "begin transaction"


# throw all of the class variables into an ns_set so that the ad_user_group_add
# will take care of putting them into the _info table

set var_set [ns_set new]

ns_set put $var_set term_id $term_id
ns_set put $var_set where_and_when $where_and_when
ns_set put $var_set start_date $start_date
ns_set put $var_set end_date $end_date
ns_set put $var_set public_p $public_p
ns_set put $var_set grades_p $grades_p
ns_set put $var_set exams_p $exams_p
ns_set put $var_set final_exam_p $final_exam_p
ns_set put $var_set description $description
ns_set put $var_set teams_p $teams_p
ns_set put $var_set subject_id $subject_id


ad_user_group_add $db edu_class $group_name t t open t $var_set $group_id

#create the role and actions for the class
edu_set_class_roles_and_actions $db $group_id

#finally, add the instructor to the class
ad_user_group_user_add $db $instructor_id [edu_get_professor_role_string] $group_id 


set depth 0
set parent_id ""

foreach folder $folder_id_list {
    ns_db dml $db "insert into fs_files
    (file_id, file_title, owner_id, parent_id, folder_p, sort_key, depth, public_p, group_id)
    values
    ([lindex $folder 1], '[DoubleApos [lindex $folder 0]]', $user_id, [ns_dbquotevalue $parent_id], 't',0,$depth, 'f', [ns_dbquotevalue $group_id])"

    # this if statement makes the first folder inserted the parent of all of
    # the rest of the folders.
    if {[empty_string_p $parent_id]} {
	set parent_id [lindex $folder 1]
	set depth 1
    }

    # now we want to insert a "dummy" version so that we can also create the permission
    # records

    ns_db dml $db "insert into fs_versions
    (version_id, file_id, creation_date, author_id)
    values
    ([lindex $folder 2], [lindex $folder 1], sysdate, $user_id)"

    ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_all_users ( 'read', [lindex $folder 2], 'FS_VERSIONS' ); 
    :1 := ad_general_permissions.grant_permission_to_all_users ( 'comment', [lindex $folder 2], 'FS_VERSIONS' ); end;"

}


fs_order_files $db $user_id $group_id $public_p


ns_db dml $db "update edu_class_info 
                      set [join $sql_update_statment ","],
       	                  last_modified = sysdate,
                          last_modifying_user = $user_id,
                          modified_ip_address = '[ns_conn peeraddr]'                      
                    where group_id = $group_id"


# create a newsgroup for this class - richardl@arsdigita.com
ns_db dml $db "insert into newsgroups(newsgroup_id, scope, group_id)
               values(newsgroup_id_sequence.nextval, 'group', $group_id)"

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect "index.tcl?subject_id=$subject_id"




