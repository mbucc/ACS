#
# /www/education/subject/index.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page displays a list of subjects
#

# optionally takes department_id.  If there is a department_id 
# defined then it only lists subjects in that department

ad_page_variables {
    {department_id ""}
}


set db [ns_db gethandle]

set threshhold 20000

set return_string "

[ad_header "[ad_system_name] - Subjects"]
<h2>Subjects</h2>

[ad_context_bar_ws "Subjects"]

<hr>
<blockquote>
<ul>
"

if {![empty_string_p $department_id]} {
    set selection [ns_db select $db "select count(subject_id) as n_subjects,
        subject_id,
        subject_name,
        subject_number
   from edu_subjects,
        edu_subject_department_map map
  where map.department_id = $department_id
    and map.subject_id = edu_subjects.subject_id
    group by subject_id, subject_name, subject_number
    order by lower(subject_number), lower(subject_name)"] 
} else {
    # they want all subjects, not just one for particular departments
    
    set selection [ns_db select $db "select count(subject_id) as n_subjects,
        subject_id,
        subject_name
   from edu_subjects
    group by subject_id, subject_name
    order by lower(subject_name)"]
}

# lets get the number of subjects

if {![ns_db getrow $db $selection]} {
    append return_string "</ul>There currently are no subjects in the system.<ul>"
} else {
    set_variables_after_query

    # now, we have all of the values set for the first row
    
    if {$n_subjects < $threshhold} {

	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    append return_string "<li><a href=\"one.tcl?subject_id=$subject_id\">$subject_name</a> \n"
	}
    }
}

append return_string "
</ul>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string










