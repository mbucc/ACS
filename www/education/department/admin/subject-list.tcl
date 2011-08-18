#
# /www/education/department/admin/subject-list.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page shows the list of subjects in the class that meet
# the passed in conditions
#

ad_page_variable {
    begin
    end
    {subjects_in_department_p t}
    {target_url ""}
    {display_text ""}
}


set db [ns_db gethandle]


# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


if {![info exists display_text]} {
    set display_text ""
}


#check the input
set exception_count 0 
set exception_display_text ""

if {[empty_string_p $begin] } {
    incr exception_count
    append exception_display_text "<li>You must have a starting letter\n"
}

if {[empty_string_p $end] } {
    incr exception_count
    append exception_display_text "<li>You must have a stopping letter\n"
}

if {[empty_string_p $lastletter] } {
    incr exception_count
    append exception_display_text "<li>You must provide a last letter\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_display_text
    return
}



if { [string compare [string tolower $begin] a] == 0) && [string compare [string tolower $end] z] == 0 } {
    set header "All Subjects"
    set sql_suffix ""
} else {
    set header "Subject Names $begin through $lastletter"
    set sql_suffix "where upper('$begin') < upper(subject_name)
               and upper('$end') > upper(subject_name)"
}



set return_string "
[ad_header "Department Administration @ [ad_system_name]"]

<h2> $header </h2>

[ad_condisplay_text_bar_ws [list "../" "Departments"] [list "" "$department_name Administration"] "Subject List"]

<hr>
<blockquote>

"

set sql_tables ""

if {[empty_string_p $sql_suffix]} {
    set sql_prefix "where"
} else {
    set sql_prefix "and"
}


if {[string compare $subjects_in_department_p f] == 0} { 
   append sql_suffix "$sql_prefix subject_id not in (select subject_id from edu_subject_department_map where department_id = $department_id)"
} else {
    append sql_tables ", edu_subject_department_map map "
    append sql_suffix "$sql_prefix map.subject_id = edu_subjects.subject_id and map.department_id = $department_id"
}


set text_to_output ""
    
set selection [ns_db select $db "select edu_subjects.subject_id, 
                                 subject_name 
                            from edu_subjects 
                                 $sql_tables
                                 $sql_suffix
                        order by lower(subject_name)"]


while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    if {![empty_string_p $target_url]} {
	append text_to_output "
	<li><a href=\"$target_url?subject_id=$subject_id\">$subject_name</a> <br> \n"
    } else {
	append text_to_output "
	<li> $subject_number $subject_name [ad_space]
	\[ <a href=\"/subject/one.tcl?subject_id=$subject_id\">home page</a> 
	| <a href=\"/subject/admin/index.tcl?subject_id=$subject_id\">admin page</a> 
	| <a href=\"subject-remove.tcl?subject_id=$subject_id\">remove</a> 
	| <a href=\"subject-number-edit.tcl?subject_id=$subject_id\">edit subject number</a> \]"
    }
}


if {[empty_string_p $display_text_to_output]} {
    append return_string "There are no subjects that meet your criteria."
} else {
    append return_string "
    $text
    $text_to_output
    "
}
    
    append return_string "
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string












