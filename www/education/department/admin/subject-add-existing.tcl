#
# /www/education/department/admin/subject-add-existing.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to add an existing subject to the department
#


set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


append return_string "

[ad_header "Add an Existing Subject @ [ad_system_name]"]
<h2>Add an Existing Subject</h2>

[ad_context_bar_ws [list "/department/" "Departments"] [list "" "$department_name Administration"] "Add a Subject"]


<hr>
<blockquote>
"

set threshhold 40
set display_text "Click on a subject to add<p>"


# get then number of subjects that are not already in the department

set n_subject [database_to_tcl_string $db "select count(subject_id) from edu_subjects where subject_id not in (select subject_id from edu_subject_department_map where department_id = $department_id)"]


# if there are < $threshhold subjects we list all of the possible subjects
# else, we provide both a broswe by subject name and a search functionality

if { $n_subject < $threshhold } {
    # display all of the subjects
    
    set selection [ns_db select $db "select subject_id, subject_name from edu_subjects where subject_id not in (select subject_id from edu_subject_department_map where department_id = $department_id) order by lower(subject_name)"]

    append return_string "$display_text<ul>"

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append return_string "
	<li><a href=\"subject-add-existing-2.tcl?subject_id=$subject_id\">$subject_name</a> <br> \n"
    }

    append return_string "</ul>"

} else {

    # there are a lot of subjects so we want to let them browse or search
    
    set subjects_in_department_p f
    set export_vars [export_url_vars target_url subjects_in_department_p display_text]

    append return_string "
    <li>Find subject by subject name : 
    <a href=subject-list.tcl?begin=A&end=H&lastletter=G&$export_vars>A - G</a> |
    <a href=subject-list.tcl?begin=H&end=N&lastletter=M&$export_vars>H - M</a> |
    <a href=subject-list.tcl?begin=N&end=T&lastletter=S&$export_vars>N - S</a> |
    <a href=subject-list.tcl?begin=T&end=z&lastletter=Z&$export_vars>T - Z</a> 
    <br><br>
    <li><a href=subject-list.tcl?begin=A&end=z&lastletter=Z&$export_vars>Show all subjects</a>

    <Br>

    <form method=get action=\"subject-search.tcl\">
    [export_form_vars target_url subjects_in_department_p display_text]
    
    <li>Search through all subjects:
    <table>
    <tr><td align=right>by Subject Name</td>
    <td><input type=text maxlength=100 size=30 name=subject_name><BR></td>
    </td>
    <tr>
    <td colspan=2>
    <center><input type=submit value=\"Search For a Subject\"></center>
    </td>
    </table>
    </form>
    "

}


append return_string "
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string












