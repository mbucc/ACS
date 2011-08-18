#
# /www/education/class/admin/handouts/upload-new-version.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January, 2000
#
# this page allows the user to upload a new version of the handout
#

ad_page_variables {
    handout_id
    {return_url ""}
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


if {[empty_string_p $handout_id]} {
    ad_return_complaint "<li>You must provide a way to identify your handout."
    return
}

set selection [ns_db 0or1row $db "select handout_name as file_title,
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
    set header "Lecture Notes"
    set folder_type lecture_notes
} else {
    set header "Handout"
    set folder_type handouts
}


if {[empty_string_p $return_url]} {
    set return_url "[edu_url]class/admin/handouts/one.tcl?handout_id=$handout_id"
} 


# in order to determine the defaults for the permissions, we want to see if there
# is already a file for the assignment (or project).  If so, we want to use 
# those as the default


if {[empty_string_p $version_id]} {
    set write_permission_default [edu_get_ta_role_string]
    set read_permission_default ""
} else {
    # lets make sure that they can edit the file
    if {![fs_check_edit_p $db $user_id $version_id $class_id]} {
	ad_return_complaint 1 "<li>You are not authorized to edit this file."
	return
    }

    # more often than not, the scope is going to be group_role so lets
    # try that one first
    set read_permission_default_list [database_to_tcl_list $db "select gp.role
        from general_permissions gp,
             edu_role_pretty_role_map map
       where on_what_id = $version_id
         and lower(on_which_table) = lower('FS_VERSIONS')
         and scope = 'group_role'
         and gp.group_id = $class_id
         and permission_type = 'read'
         and gp.group_id = map.group_id
         and lower(gp.role) = lower(map.role)
       order by priority desc"]

    # we want the highest numerical priority so lets just grab the first element
    set read_permission_default [lindex $read_permission_default_list 0]
    if {[empty_string_p $read_permission_default]} {
	# if there is not a group_role item, we just set our normal default
	# read role of ""
	set read_permission_default ""
    }


    # now, we want to set our default write permissions and we do pretty much
    # the same thing as when we did the read permissions.

    set write_permission_default_list [database_to_tcl_list $db "select gp.role
        from general_permissions gp,
             edu_role_pretty_role_map map
       where on_what_id = $version_id
         and lower(on_which_table) = lower('FS_VERSIONS')
         and scope = 'group_role'
         and gp.group_id = $class_id
         and permission_type = 'write'
         and gp.group_id = map.group_id
         and lower(gp.role) = lower(map.role)
       order by priority desc"]

    # we want the highest numerical priority so lets just grab the first element
    set write_permission_default [lindex $write_permission_default_list 0]
    if {[empty_string_p $write_permission_default]} {
	# there was not a group_role so lets check if it is public
	set write_permission_public_p [database_to_tcl_string_or_null $db "select decode(ad_general_permissions.all_users_permission_id('write', $version_id, 'FS_VERSIONS'),0,0,1) from dual"]
	if {$write_permission_public_p == 0} {
	    # if write_permisssion_public_p is 0 then there is not a correct permissions
	    # record so we go to our usual default of ta
	    set write_permission_default [edu_get_ta_role_string]
	} 
    }
}


set return_string "
[ad_header "$header @ [ad_system_name]"]

<h2>Upload New Version</h2>

of $file_title
<p>
[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" Handouts] "$header"]

<hr>

<blockquote>

<form enctype=multipart/form-data method=post action=\"upload-version.tcl\">
[export_form_vars file_id version_description file_title return_url]

<table>
<tr>
<th align=right>File Title: </td>
<td valign=top>
$file_title
</td>
</tr>

<tr>
<th align=right> Date Distributed: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $distribution_date]
</td>
</tr>

<tr>
<th valign=top align=right> Description: </td>
<td valign=top>
[edu_maybe_display_text $version_description]
</td>
</tr>

[edu_file_upload_widget $db $class_id $folder_type $read_permission_default $write_permission_default f]

<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Upload new $header\">
</td>
</tr>
</table>
</form>

</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string
