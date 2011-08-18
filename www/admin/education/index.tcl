#
# /www/admin/education/index.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page is the index to the educational system
#

# this page does not expect any input


set db [ns_db gethandle]


set return_string "
[ad_admin_header "[ad_system_name] Administration"]
<h2>Education Administration</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] "Education Administration"]

<hr>
<blockquote>

<h3>Departments</h3>
<ul>
"

set count 0

set selection [ns_db select $db "select department_name, department_id from edu_departments order by lower(department_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append return_string "<li>$department_name <a href=\"/education/util/group-login.tcl?group_id=$department_id&group_type=edu_department&return_url=[ns_urlencode "/education/department/admin/"]\">admin page</a> 
    | <a href=\"/education/util/group-login.tcl?group_id=$department_id&group_type=edu_department&return_url=[ns_urlencode "/education/department/one.tcl"]\">home page</a>"
    incr count
}

if {$count == 0} {
    append return_string "There are currently no departments in the system."
} else {
    append return_string "<br>"
}

set n_subjects [database_to_tcl_string $db "select count(subject_name) from edu_subjects"]

if {$n_subjects > 0} {
    set subject_string "<a href=\"/education/subject/\">$n_subjects</a>"
} else {
    set subject_string 0
}

set n_textbooks [database_to_tcl_string $db "select count(textbook_id) from edu_textbooks"]

if {$n_textbooks > 0} {
    set textbook_string "<a href=\"textbooks.tcl\">$n_textbooks</a>"
} else {
    set textbook_string 0
}

append return_string "
<Br>
<a href=\"department-add.tcl\">Add a Department</a>
</ul>

<h3>Reports</h3>
<ul>

<li> Terms (<a href=\"terms.tcl\">[database_to_tcl_string $db "select count(term_id) from edu_terms"]</a>)

<li> Subjects ($subject_string)

<li> Users (<a href=\"/admin/users/\">[database_to_tcl_string $db "select count(user_id) from users where user_id > 2"]</a>)

<li> Textbooks ($textbook_string)
</ul>


</blockquote>

[ad_admin_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string
