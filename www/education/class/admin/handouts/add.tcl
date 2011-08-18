#
# /www/education/class/admin/handouts/add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January, 2000
#
# this page is where teachers can go to issue tasks (assignments or projects)
# basically, they are able to upload a file/url into the file storage
# system and then associate a due date with it.
#

ad_page_variables {
    type
}

# we expect 'type' to be something like 'announcement' or 'lecture_notes'

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set file_id [database_to_tcl_string $db "select fs_file_id_seq.nextval from dual"]
set handout_id [database_to_tcl_string $db "select edu_handout_id_sequence.nextval from dual"]


if {[string compare $type lecture_notes] == 0} {
    set folder_type lecture_notes
    set header "Upload New Lecture Notes"
} else {
    set folder_type handouts
    set header "Upload New Handout"
}    


set return_string "
[ad_header "$header @ [ad_system_name]"]

<h2>$header</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" Handouts] "$header"]

<hr>

<blockquote>


<form enctype=multipart/form-data method=post action=\"add-2.tcl\">
[export_form_vars type file_id handout_id]
<table>
<tr>
<th align=right>File Title: </td>
<td valign=top>
<input type=text size=30 maxsize=100 name=file_title>
</td>
</tr>

<tr>
<th valign=top align=right> Description: </td>
<td valign=top>
[edu_textarea version_description "" 50 6]
</td>
</tr>

<tr>
<th align=right> Date Distributed: </td>
<td valign=top>
[ad_dateentrywidget distribution_date]
</td>
</tr>

[edu_file_upload_widget $db $class_id $folder_type "" [edu_get_ta_role_string] f]

<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"$header\">
</td>
</tr>
</table>
</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string

