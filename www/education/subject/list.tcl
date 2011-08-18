#
# /www/education/subject/list.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page lists the subjects that meet the passed in criteria
#

ad_page_variables {
    begin
    end
    {department_id ""}
    {return_url ""}
    {display_text ""}
}


set db [ns_db gethandle]



#check the input
set exception_count 0 
set exception_text ""

if {[empty_string_p $begin] } {
    incr exception_count
    append exception_text "<li>You must have a starting letter\n"
}

if {[empty_string_p $end] } {
    incr exception_count
    append exception_text "<li>You must have a stopping letter\n"
}

if {[empty_string_p $lastletter] } {
    incr exception_count
    append exception_text "<li>You must provide a last letter\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}




if { [string compare [string tolower $begin] a] == 0 && ([string compare [string tolower $end z] == 0 } {
    set header "All Subject"
    set sql_suffix ""
} else {
    set header "Subject Names $begin through $lastletter"
    set sql_suffix "upper('$begin') < upper(subject_name)
               and upper('$end') > upper(subject_name)"
}


set return_string "
[ad_header "Subject Administration @ [ad_system_name]"]

<h2> $header </h2>

[ad_context_bar_ws [list "" Subjects] Subjects]

<hr>
<blockquote>

"
if {![empty_string_p $department_id]} {
    set selection [ns_db select $db "select subject_id,
        subject_name,
        subject_number
   from edu_subjects,
        edu_subject_department_map map
  where map.department_id = $department_id
    and map.subject_id = edu_subjects.subject_id
    and $sql_suffix
    order by lower(subject_number), lower(subject_name)"] 
} else {
    # they want all subjects, not just one for particular departments
    
    set selection [ns_db select $db "select subject_id,
        subject_name
   from edu_subjects
  where $sql_suffix
  order by lower(subject_name)"]
}


while {[ns_db getrow $db $selection]} {
    set_variables_after_query    
    append text_to_output "<a href=\"one?subject_id=$subject_id\">$subject_name <br> \n"
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













