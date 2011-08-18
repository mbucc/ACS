#
# /www/education/subject/one.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page show information about the requested subject
#


ad_page_variables {
    subject_id 
}


if {[empty_string_p $subject_id]} {
    ad_return_complaint 1 "<li> You must include a subject identification number."
    return
}


set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select subject_name, description, credit_hours, prerequisites, professors_in_charge from edu_subjects where subject_id = $subject_id"]

if {$selection == ""} {
    ad_return_complaint 1 "<li> The subject identification number you have entered is not valid."
    return
} else {
    set_variables_after_query
}



set return_string "

[ad_header "[ad_system_name] - Add a Subject"]
<h2>$subject_name</h2>

[ad_context_bar_ws [list "" "Subjects"] "One Subject"]

<hr>
<blockquote>

<table>

<tr>
<th align=left valign=top>
Subject Name:
</td>
<td>
$subject_name
</td>
</tr>

<tr>
<th align=left valign=top>
Description:
</td>
<td>
[address_book_display_as_html $description]
</td>
</tr>

<tr>
<th align=left valign=top>
Credit Hours:
</td>
<td>
$credit_hours
</td>
</tr>

<tr>
<th align=left valign=top>
Prerequisites:
</td>
<td>
[address_book_display_as_html $prerequisites]
</td>
</tr>

<tr>
<th align=left valign=top>
Professors in Charge:
</td>
<td>
$professors_in_charge
</td>
</tr>

</table>

<h3>Departments</h3>
<ul>
"

set selection [ns_db select $db "select map.department_id, 
      department_name, 
      subject_number 
 from edu_subject_department_map map, 
      edu_departments 
where edu_departments.department_id = map.department_id 
  and map.subject_id = $subject_id"]


set n_departments 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr n_departments
    append return_string "<li><a href=\"../department/one.tcl?department_id=$department_id\">$department_name</a>; $subject_number \n"
}

if {$n_departments == 0} {
    append return_string "<li>This subject is not currently affiliated with any department."
}


append return_string "
</ul>
<h3>Classes</h3>
<ul>
"

set count 0
set selection [ns_db select $db "select class_name, class_id, term_name
from edu_terms t, edu_classes c
where c.subject_id=$subject_id
and c.term_id=t.term_id
order by
t.start_date"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr count
    append return_string "
    <li><a href=\"../class/one.tcl?[export_url_vars class_id]\">$class_name ($term_name)</a>"
}

if {$count == 0} {
    append return_string "There are currently no classes in this subject."
}

append return_string "
</ul>

</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string




