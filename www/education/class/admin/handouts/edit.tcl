#
# /www/education/class/admin/handouts/edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page is where teachers can go to edit assignments (or projects).
# basically, they are able to upload a file/url into the file storage
# system and then associate a due date with it.
#

ad_page_variables {
    handout_id
    {return_url ""}
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


if {[empty_string_p $handout_id]} {
    ad_return_complaint "<li>You must provide a way to identify your handout."
    return
}

set selection [ns_db 0or1row $db "select handout_name,
       edu_handouts.file_id,
       handout_type,
       version_id,
       file_extension,
       version_description,
       url,
       handout_type,
       distribution_date
  from edu_handouts,
       (select * from fs_versions_latest 
        where ad_general_permissions.user_has_row_permission_p($user_id, 'write', version_id, 'FS_VERSIONS') = 't') ver
 where class_id = $class_id
   and handout_id = $handout_id
   and edu_handouts.file_id = ver.file_id"]


if {$selection == ""} {
    ad_return_complaint 1 "<li>The handout you are trying to view is not part of this class and therefore you are not authorized to view it at this time."
    return
} else {
    set_variables_after_query
}



if {[string compare $handout_type lecture_notes] == 0} {
    set pretty_type "Lecture Notes"
} else {
    set pretty_type "Handout"
}


set return_string "
[ad_header "Edit $pretty_type @ [ad_system_name]"]

<h2>Edit $pretty_type</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] [list "" Handouts] "Edit $pretty_type"]

<hr>

<blockquote>

<form method=POST action=\"edit-2.tcl\">
[export_form_vars return_url handout_id]

<table>
<tr>
<th align=right>File Title: </td>
<td valign=top>
<input type=text size=30 maxsize=200 value=\"$handout_name\" name=file_title>
</td>
</tr>

<tr>
<th align=right>
Date Distributed:
</td>
<td valign=top>
[ad_dateentrywidget distribution_date $distribution_date]
</td>
</tr>

<tr>
<th valign=top align=right>
Description:
</td>
<td>
[edu_textarea version_description $version_description 50 6]
</td>
</tr>

<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Edit $pretty_type\">
</td>
</tr>
</table>

</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
