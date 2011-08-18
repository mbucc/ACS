#
# /www/education/department/admin/subject-search.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this is a subject search page that is used in two different cases.
# first, if someone is added a subject to the department then it
# displays the subject name and links to the target_url
# second, this could be someone in the department asking for information
# about a particlar subject.  When this is the case, we want to provide
# all of the necessary links.
#

ad_page_variables {
    begin
    end
    {subjects_in_department_p t}
    {target_url ""}
    {text ""}
}


set db [ns_db gethandle]


# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


#check the input
set exception_count 0 
set exception_text ""



if { (![info exists subject_name] || $subject_name == "") && (![info exists professor] || $professor == "") } {
    incr exception_count
    append exception_text "<li>You must specify either an subject_name or professor to search for.\n"
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if {[info exists subject_name] && $subject_name != "" && [info exists professor] && $professor != ""} {
    set search_text "subject name \"$subject_name\" and professor \"$professor\""
    set search_clause "lower(subject_name) like '%[string tolower $subject_name]%' and lower(professors_in_charge) like '%[string tolower $professor]%'"
} elseif { [info exists subject_name] && $subject_name != "" } {
    set search_text "subject name \"$subject_name\""
    set search_clause "lower(subject_name) like '%[string tolower $subject_name]%'"
} else {
    set search_text "professor \"$last_name\""
    set search_clause "lower(professors_in_charge) like '%[string tolower $professor]%'"
}




set return_string "
[ad_header "Department Administration @ [ad_system_name]"]

<h2> Subject Search </h2>
$search_text
<br><br>
[ad_context_bar_ws [list "/department/" "Departments"] [list "" "$department_name Administration"] "Subject Search"]

<hr>
<blockquote>

"

set sql_tables ""


if {[string compare $subjects_in_department_p f] == 0} { 
   append search_clause "and subject_id not in (select subject_id from edu_subject_department_map where department_id = $department_id)"
} else {
    append sql_tables ", edu_subject_department_map map "
    append search_clause "and map.subject_id = edu_subjects.subject_id and map.department_id = $department_id"
}


set text_to_output ""
    
set selection [ns_db select $db "select edu_subjects.subject_id, 
                                 subject_name 
                            from edu_subjects 
                                 $sql_tables
                                 where $search_clause
                        order by lower(subject_name)"]


while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    if {![empty_string_p $target_url]} {
	append text_to_output "
	<li><a href=\"$target_url?subject_id=$subject_id\">$subject_name</a> <br> \n"
    } else {
	append text_to_output "<li> $subject_number $subject_name &nbsp &nbsp\[ <a href=\"/subject/one.tcl?subject_id=$subject_id\">home page</a> | <a href=\"/subject/admin/index.tcl?subject_id=$subject_id\">admin page</a> | <a href=\"subject-remove.tcl?subject_id=$subject_id\">remove</a> | <a href=\"subject-number-edit.tcl?subject_id=$subject_id\">edit subject number</a> \]"
    }
}


if {[empty_string_p $text_to_output]} {
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







