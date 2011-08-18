#
# /www/education/class/admin/handouts/one.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January, 2000
#
# this page is where teachers can go to issue tasks (assignments or projects)
# basically, they are able to upload a file/url into the file storage
# system and then associate a due date with it.
#

ad_page_variables {
    handout_id
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


# the first thing we want to do is check and make sure that 
# the given handout is not null and a part of this class

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
       distribution_date,
       ad_general_permissions.user_has_row_permission_p($user_id, 'write', version_id, 'FS_VERSIONS') as write_p
  from edu_handouts,
       fs_versions_latest ver
 where class_id = $class_id
   and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't'
   and handout_id = $handout_id
   and edu_handouts.file_id = ver.file_id"]


if {$selection == ""} {
    ad_return_complaint 1 "<li>The handout you are trying to view is not part of this class and therefore you are not authorized to view it at this time."
    return
} else {
    set_variables_after_query
}


#
# the security has not been taken care of...let's display the handout
#


if {[string compare $handout_type lecture_notes] == 0} {
    set header "Lecture Notes"
    set folder_type lecture_notes
} else {
    set header "Handout"
    set folder_type handouts
}


set return_string "
[ad_header "$header @ [ad_system_name]"]

<h2>$handout_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" Handouts] "One $header"]

<hr>

<blockquote>

<table>
<tr>
<th valign=top align=right>File Title: </td>
<td valign=top>
"

if {![empty_string_p $url]} {
    append return_string "<a href=\"$url\">$handout_name</a>"
} elseif {![empty_string_p $version_id]} {
    append return_string "<a href=\"/file-storage/download/[join $handout_name "_"].$file_extension?version_id=$version_id\">$handout_name</a>"
} else {
    append return_string "$handout_name"
}


append return_string "
</td>
</tr>

<tr>
<th valign=top align=right>
Date Distributed:
</td>
<td valign=top>
[util_AnsiDatetoPrettyDate $distribution_date]
</td>
</tr>

<tr>
<th valign=top align=right>
Description:
</td>
<td>
[edu_maybe_display_text $version_description]
</td>
</tr>
</table>
<p>
"

if {[string compare $write_p t] == 0} {
    append return_string "
    <a href=\"edit.tcl?handout_id=$handout_id\">edit</a> 
    |
    <a href=\"upload-new-version.tcl?handout_id=$handout_id\">upload a new version</a>
    |
    "
}

append return_string "
<a href=\"delete.tcl?handout_id=$handout_id\">delete</a>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
