#
# /www/education/subject/admin/index.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this page is the front page seen by the person running the subject
#

ad_page_variables {
    subject_id
}


if {[empty_string_p $subject_id]} {
    ad_return_complaint 1 "<li> You must provide a subject identification number."
    return
}


set db [ns_db gethandle]

set user_id [edu_subject_admin_security_check $db $subject_id]

set selection [ns_db 0or1row $db "select subject_name, description, credit_hours, prerequisites, professors_in_charge from edu_subjects where subject_id = $subject_id"]

if {$selection == ""} {
    ad_return_complaint 1 "<li> The subject identification number you have entered is not valid."
    return
} else {
    set_variables_after_query
}


# if they are a site wide admin we want to give them all possible links

set site_wide_admin_p [ad_administrator_p $db $user_id]



set return_string "
[ad_header "Subject Administration @ [ad_system_name]"]

<h2>$subject_name</h2>

[ad_context_bar_ws [list "../" "Subjects"] "Subject Administration"]

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

<tr>
<td colspan=2 align=left valign=top>
(<a href=\"edit.tcl?subject_id=$subject_id\">edit</a>)
</tr>
</table>

<h3>Departments</h3>
<ul>
"

# we are doing the view on the fly so that we can tell if the person is
# an admin for the given deparment so we know whether or not to show the
# link

set selection [ns_db select $db "select map.department_id, 
                     department_name, 
                     subject_number,
                     grad_p,
                     count(admin_list.group_id) as department_admin_p
                from edu_subject_department_map map, 
                     edu_departments dept,
                     (select group_id 
                             from user_group_map 
                            where user_id = $user_id 
                              and role = 'administrator') admin_list
               where dept.department_id = map.department_id 
                  and map.subject_id = $subject_id
                  and map.department_id = admin_list.group_id(+)
             group by map.department_id, 
                      department_name, 
                      subject_number, 
                      grad_p"]



set n_departments 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr n_departments

    if {[string compare $grad_p t] == 0} {
	set grad_tag G
    } else {
	set grad_tag ""
    }

    append return_string "<li><a href=\"/education/util/group-login.tcl?group_id=$department_id&group_type=edu_department&return_url=[ns_urlencode "[edu_url]department/one.tcl"]\">$department_name</a>; $subject_number $grad_tag \n"

    # if they are an admin, give them a link to the admin pages
    if {$department_admin_p > 0 || $site_wide_admin_p} {
	append return_string "[ad_space 2] \[ <a href=\"/education/util/group-login.tcl?group_id=$department_id&group_type=edu_department&return_url=[ns_urlencode [edu_url]department/admin/]\">admin page</a> \]"
    }
}

if {$n_departments == 0} {
    append return_string "<li>This subject is not currently affiliated with any department."
}


# if the person is a site-wide admin, give them the option to add a 
# department if there are still departments that do not have this subject
# else,
# give the person the option to add this subject to a department if they
# are the admin of the department and the subject is not already in
# the given deparmtment
# else,
# don't give a link to add a department

set n_other_departments 0

if { $site_wide_admin_p == 1 } {
    set n_other_departments [database_to_tcl_string $db "select count(department_id) from edu_departments"]
} else {
    # we want to select the departments that the person is admin for 
    # but are not currently affiliated with the subject
    set n_other_departments [database_to_tcl_string $db "select count(dept.department_id)
                                from user_group_map map,
                                     edu_departments dept
                               where map.group_id = dept.department_id
                                 and map.user_id = $user_id
                                 and dept.department_id not in (select
                                           sdmap.department_id
                                           from edu_subject_department_map sdmap
                                          where sdmap.subject_id = $subject_id)
                            order by lower(department_name)"]
}

if {$n_departments < $n_other_departments} {
    append return_string "
    <br><br>
    <li><a href=\"department-add.tcl?[export_url_vars subject_id subject_name]\">Add this subject to a department</a>
    "
}


append return_string "
<p>

</ul>
<h3>Classes</h3>
<ul>
"


set classes [database_to_tcl_list_list $db "select class_name, 
     class_id, 
     term_name
from edu_terms t, 
     edu_classes c
where c.subject_id=$subject_id
and c.term_id=t.term_id
order by
t.start_date, lower(class_name)"]

set return_url "[edu_url]class/admin/"

foreach class $classes {
    append return_string "
    <li><a href=\"/education/util/group-login.tcl?group_id=[lindex $class 1]&group_type=edu_class&return_url=[ns_urlencode [edu_url]class/one.tcl]\">[lindex $class 0] ([lindex $class 2])</a>"

    # we show the link to the admin page only if they have permission to see it

    if {[ad_permission_p $db "" "" "View Admin Pages" $user_id [lindex $class 1]] || $site_wide_admin_p} {
	append return_string "
	[ad_space] \[ <a href=\"/education/util/group-login.tcl?group_type=edu_class&group_id=[lindex $class 1]\&[export_url_vars return_url]\">admin page</a> \] <br> \n"
    }
}

set target_url "class-add.tcl"
set param_list [list [export_url_vars subject_id]]

set browse_type "select_instructor"

append return_string "
<BR>
<a href=\"users.tcl?[export_url_vars target_url param_list subject_id browse_type]\">Add a Class</a>
</ul>

</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string




