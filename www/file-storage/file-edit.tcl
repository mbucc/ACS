# /file-storage/file-edit.tcl
ad_page_contract {
    Allows the user to edit information about a file.

    @author dh@arsdigita.com
    @creation-date July 1999
    @cvs-id file-edit.tcl,v 3.4.6.4 2000/09/22 01:37:47 kevin Exp 

    modified by randyg@arsdigita.com January 2000 to use the general permissions system
} {
    {return_url}
    {file_id:integer}
    {group_id ""}
}

set user_id [ad_maybe_redirect_for_registration]

set title "Edit Properties"

set exception_text ""
set exception_count 0

if [empty_string_p $file_id]  {
    incr exception_count
    append exception_text "<li>No file was specified"
}

set version_id [db_string version "select version_id
                                   from fs_versions_latest
                                   where file_id = :file_id" -default ""]

if { [empty_string_p $version_id]} {
    incr exception_count
    append exception_text "<li>The file you have requested does not exist."

} elseif { ![fs_check_edit_p $user_id $version_id $group_id] } {

    incr exception_count
    append exception_text "<li>You do not own this file"

}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

db_1row file_information "
    select fsf.file_title,
           decode ( fsf.folder_p, 't', 'Folder', 'File') as object_type,
           fsvl.file_type,
           ad_general_permissions.user_has_row_permission_p ( :user_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) as public_read_p,
           fsf.public_p
    from   fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.file_id = :file_id
    and    fsf.file_id = fsvl.file_id"

if ![empty_string_p $group_id] {
    set group_name [db_string group_name_get "
    select group_name 
    from   user_groups 
    where  group_id=:group_id"]
    
    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]\
	                          [list "private-one-group?group_id=$group_id" $group_name]\
				  [list $return_url "One File"]\
				  $title]
} else {
    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]\
	                          [list $return_url "One File"]\
				  $title]
}

set page_content "[ad_header $title]

<h2>$title</h2>

$navbar

<hr align=left>
<blockquote>
<form method=POST action=file-edit-2>

[export_form_vars file_id version_id return_url group_id object_type]

<table>
<tr>
<td align=right>$object_type Title: </td>
<td><input size=30 name=file_title value=\"$file_title\"></td>
</tr>"

if { $object_type == "File" } {
    append page_content "
    <tr>
    <td align=right>File Type: </td>
    <td><input size=30 name=file_type value=\"$file_type\"></td>"
}

append page_content "

<tr>
<td align=right>Location:</td>
<td>[fs_folder_selection $user_id $group_id $public_p $file_id]</td>
</tr>

<tr>
<td></td>
<td><input type=submit value=\"Update\">
</td>
</tr>
</table>

</form>

<h3>Severe actions</h3>

<ul>
<li><a href=file-delete?[export_url_vars group_id file_id return_url object_type]>Delete this $object_type</a>

</ul>
</blockquote>
[ad_footer [fs_system_owner]]"

# serve the page

doc_return  200 text/html $page_content

