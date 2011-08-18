#
# /www/education/department/admin/index.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page displays the information for the department the person
# is logged in as
#

set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]

set subject_threshhold 20000
set class_threshhold 20000

set selection [ns_db 0or1row $db "select department_name, 
                         department_number, 
                         external_homepage_url,
                         mailing_address,
                         phone_number,
                         fax_number,
                         inquiry_email,
                         description,
                         mission_statement
                   from edu_departments
                  where department_id = $department_id"]

if {$selection == ""} {
    # this should never, ever happen because of the call to edu_group_security_check
    ad_return_complaint 1 "<li> The group that you are logged in as is not a department.  Please return to <a href=\"/pvt/home.tcl\">your home page</a> and try again."
    return
} else {
    set_variables_after_query
}



set return_string "

[ad_admin_header "Department Administration @ [ad_system_name]"]

<h2>Department Administration</h2>


[ad_context_bar_ws [list "../" "Departments"] "$department_name Administration"]


<hr>
<blockquote>

<h3>$department_name</h3>
<table>

<tr>
<th align=left valign=top>
Department Number
</td>
<td>
[edu_maybe_display_text $department_number]
</td>
</tr>

<tr>
<th align=left valign=top>
External Homepage URL
</td>
<td>
"

if {![empty_string_p $external_homepage_url]} {
    append return_string "<a href=\"$external_homepage_url\">$external_homepage_url</a>"
} else {
    append return_string "Nonee"
}

append return_string "
</td>
</tr>

<tr>
<th align=left valign=top>
Mailing Address
</td>
<td>
[edu_maybe_display_text $mailing_address]
</td>
</tr>


<tr>
<th align=left valign=top>
Phone Number
</td>
<td>
[edu_maybe_display_text $phone_number]
</td>
</tr>

<tr>
<th align=left valign=top>
Fax Number
</td>
<td>
[edu_maybe_display_text $fax_number]
</td>
</tr>

<tr>
<th align=left valign=top>
Inquiry Email Address
</td>
<td>
[edu_maybe_display_text $inquiry_email]
</td>
</tr>

<tr>
<th align=left valign=top>
Description
</td>
<td>
[edu_maybe_display_text [address_book_display_as_html $description]]
</td>
</tr>

<tr>
<th align=left valign=top>
Mission Statement
</td>
<td>
[edu_maybe_display_text [address_book_display_as_html $mission_statement]]
</td>
</tr>

<tr>
<td colspan=2 align=left>
(<a href=\"department-edit.tcl\">edit</a>)
</td>
</tr>

</table>

<p>

<a href=\"users/\">User Management</a>

<p>
"


# now, lets list the subjects and classes in the department 

set selection [ns_db 1row $db "select count(unique(map.subject_id)) as n_subjects, 
                        count(class_id) as n_classes 
                   from edu_classes, 
                        edu_subject_department_map map 
                  where map.subject_id = edu_classes.subject_id(+) 
                    and map.department_id = $department_id"]

set_variables_after_query


set subject_text "
<h3>Subjects</h3>
<ul>

"

if {$n_subjects == 0} {
    append subject_text "There currently are no subjects in this department."
} elseif {$n_subjects < $subject_threshhold} {
    # we want to list the subjects
    set selection [ns_db select $db "select subject_name, 
                        map.subject_number, 
                        map.subject_id,
                        map.grad_p
                   from edu_subjects, 
                        edu_subject_department_map map 
                  where map.subject_id = edu_subjects.subject_id 
                    and map.department_id = $department_id 
               order by lower(subject_number), lower(subject_name)"]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {[string compare $grad_p t] == 0} {
	    set grad_tag G
	} else {
	    set grad_tag ""
	}

	append subject_text "<li> $subject_number $grad_tag $subject_name [ad_space 2]
	\[ <a href=\"[edu_url]subject/one.tcl?subject_id=$subject_id\">home page</a> 
	| <a href=\"[edu_url]subject/admin/index.tcl?subject_id=$subject_id\">admin page</a> 
	| <a href=\"subject-remove.tcl?subject_id=$subject_id\">remove</a> 
	| <a href=\"subject-status-edit.tcl?subject_id=$subject_id\">edit</a> \]\n"
    }


}


    if {[database_to_tcl_string $db "select count(subject_id) from edu_subjects where subject_id not in (select subject_id from edu_subject_department_map where department_id = $department_id)"] > 0 } {
	# only display this link if there are more subjects to add.
	append subject_text "<br><Br><a href=\"subject-add-existing.tcl\">Add an Existing Subject</a> [ad_space] \n"
    }
    append subject_text "<br><br><a href=\"subject-add.tcl\">Add a New Subject</a></ul>"


#
# now do the classes
#




set class_text "
<h3>Classes</h3>
<ul>

"

if {$n_classes == 0} {
    append class_text "There currently are no classes in this department.</ul>"
} elseif {$n_classes < $class_threshhold} {
    # we want to list the subjects
    set selection [ns_db select $db "select class_name, 
            class_id 
       from edu_classes, 
            edu_subjects, 
            edu_subject_department_map map 
      where map.subject_id = edu_classes.subject_id
        and map.department_id = $department_id
        and edu_subjects.subject_id = map.subject_id"]

    set return_url "[edu_url]class/admin/"

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	append class_text "<li> $class_name [ad_space 2] 
	\[<a href=\"/education/util/group-login.tcl?group_id=$class_id&group_type=edu_class&return_url=[ns_urlencode [edu_url]class/one.tcl]\">home page</a> 
	| <a href=\"/education/util/group-login.tcl?group_id=$class_id&group_type=edu_class&[export_url_vars return_url]\">admin page</a>\]"
    }

    append class_text "</ul>"

}

append return_string "
$subject_text
$class_text
</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string

