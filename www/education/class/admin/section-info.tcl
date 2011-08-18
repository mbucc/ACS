#
# /www/education/class/admin/section-info.tcl
#
# randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page displays information about the section
#

ad_page_variables {
    section_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {![info exists section_id] || [empty_string_p $section_id]} {
    incr exception_count
    append exception_text "<li>You must provide a section number."
} else {
    set selection [ns_db 0or1row $db "select
                     section_name,
                     section_place,
                     section_time
                from edu_sections
               where section_id = $section_id
                 and class_id = $class_id"]

    if {$selection == ""} {
	incr exception_count
	append exception_text "<li>The section number that you have provided is not a section in this class."
    } else {
	set_variables_after_query
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set return_string ""
[ad_header "View Section for $class_name @ [ad_system_name]"]
<h2>$class_name Teams</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" Administration] "One Section"]

<hr>

<blockquote>

<table>

<tr>
<th align=right>
Section Name:
</td>
<td>
$section_name
</td>
</tr>

<tr>
<th align=right>
Section Location:
</td>
<td>
$section_place
</td>
</tr>

<tr>
<th align=right>
Section Time:
</td>
<td>
$section_time
</td>
</tr>

<tr>
<td align=right>
(<a href=\"section-add-edit.tcl?section_id=$section_id\">edit</a>)
</td>
<td>
</td>
</tr>

</table>

"


# now, lets find the section leaders

# we need the distinct so that we don't repeat for users that have
# multiple roles in the group

set selection [ns_db select $db "select 
                     distinct users.user_id, 
                     first_names || ' ' || last_name as user_name,
                     fm.sort_key,
                     email,
                     url,
                     fm.field_name, 
                     fm.field_value
                from users,
                     user_group_map map, 
                     (select fm.field_name, 
                             fm.field_value,
                             tmf.sort_key,
                             fm.user_id
                        from user_group_type_member_fields tmf,
                               user_group_member_field_map fm
                         where group_type = 'edu_class'
                           and fm.group_id = $class_id
                           and tmf.field_name = fm.field_name) fm
               where users.user_id = map.user_id
                 and (lower(map.role) = 'administrator' 
                     or lower(map.role) = lower('[edu_get_professor_role_string]')
                     or lower(map.role) = lower('[edu_get_ta_role_string]')) 
                 and map.group_id = $section_id
                 and map.user_id=fm.user_id(+)
            order by last_name, first_names, sort_key"]


# we use old_user_id here because the above query can potentially
# return more than one row for each user.  For instance, for a prof,
# it will return one row for the office location, phone number, and
# office hours.  Since we only want to display the name once, we only
# add the text once.

set teacher_text ""
set old_user_id ""

set leader_count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    if {$old_user_id!=$user_id} {
	incr leader_count
	if {$old_user_id!=""} {
	    append leader_text "<li><a href=\"section-user-remove.tcl?section_id=$section_id&leader_id=$old_user_id\">remove from section</a><br><br></ul>"
	}

	if {![empty_string_p $url]} {
	    set user_name "<a href=\"$url\">$user_name</a>"
	}
	append leader_text "<li>$user_name (<a href=\"mailto:$email\">$email</a>) \n"
	set old_user_id $user_id
	append leader_text "<ul>"
    } 

    if {![empty_string_p $field_value]} {
	append leader_text "<li><b>$field_name</b>: [edu_maybe_display_text $field_value] \n"
    }
}


append return_string "
<h3>Sections Leaders</h3>
<ul>
$leader_text
"

if {$leader_count > 0} {
    append return_string "
    <li><a href=\"section-user-remove.tcl?section_id=$section_id&leader_id=$user_id\">remove from section</a>
    </ul>
    "
} else {
    append return_string "There are no Leaders for this section."
}

# if there are TAs and/or Profs that are in the class but are not yet in the
# section
# we need the distinct because it is now possible for users to have several
# roles in one group

if {[database_to_tcl_string $db "select count(distinct user_id) from user_group_map where group_id = $class_id and (lower(role) = lower('[edu_get_ta_role_string]') or lower(role) = lower('administrator') or lower(role) = lower('[edu_get_professor_role_string]'))"] > $leader_count} {

    set target_url "../section-user-add.tcl"
    set target_url_params "section_id=$section_id"
    append return_string "
    <br>
    <li><a href=\"users/index.tcl?section_id=$section_id&type=section_leader&[export_url_vars target_url_params target_url]\">Add a Leader</a>
    "
}

append return_string "
</ul>
<h3>Section Members</h3>
<ul>
"

set selection [ns_db select $db "select distinct users.user_id as student_id, 
             last_name || ', ' || first_names as student_name 
        from user_group_map map, 
             users 
       where map.user_id = users.user_id
         and map.group_id = $section_id
         and lower(map.role) = lower('member')
     order by last_name"]

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append return_string "<li><a href=\"users/student-info.tcl?student_id=$student_id\">$student_name</a> &nbsp &nbsp (<a href=\"section-user-remove.tcl?student_id=$student_id&section_id=$section_id\">remove from section</a>)\n"
    incr count
}

if {$count == 0} {
    append return_string "There are not currently any students assigned to this section."
}


# if there are users in the class but not in the section then display the link

if {[database_to_tcl_string $db "select count(distinct user_id) from user_group_map where group_id = $class_id and lower(role) = lower('[edu_get_student_role_string]')"] > $count} {
    append return_string "
    <p>
    <a href=\"users/students-view.tcl?view_type=section&section_id=$section_id&target_url=[ns_urlencode "../section-user-add.tcl"]&target_url_vars=[ns_urlencode "section_id=$section_id"]\">Add a Section Member</a>
    "
}

append return_string "
</ul>
"

append return_string "
<a href=\"spam.tcl?who_to_spam=[ns_urlencode [list administrator member]]&subgroup_id=$section_id\">Spam Section</a>

</ul>

</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string







