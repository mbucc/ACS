# file-edit.tcl
ad_page_contract {
    @cvs-id file-edit.tcl,v 3.5.2.4 2000/09/22 01:35:13 kevin Exp
} {
    file_id:integer
    public_p
    return_url
    {group_id ""}
}

set title "Edit Properties"

set exception_text ""
set exception_count 0

if {(![info exists group_id])||([empty_string_p $group_id]) } {
    set group_id ""
}

if {(![info exists file_id])||([empty_string_p $file_id])} {
    incr exception_count
    append exception_text "<li>No file was specified"
}

set owner_id [db_string unused "select owner_id from fs_files where file_id=:file_id"]
## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# get the owner_id of this file
set owner_id [db_string unused "select owner_id from fs_files where file_id=:file_id"]
set file_title [db_string unused "select file_title from fs_files where file_id=:file_id"]

## get the object type of this file_id
if {[db_string unused "select folder_p from fs_files where file_id=:file_id"]=="t" } {
    set object_type "Folder"
} else {
    set object_type "File"
}

## get the current location of the file (ie parent_id)
set current_parent_id [db_string unused "select parent_id from fs_files where file_id=:file_id"]

if { [info exists group_id] && ![empty_string_p $group_id]} {
    set group_name [db_string unused "
    select group_name 
    from   user_groups 
    where  group_id=:group_id"]
    
    set navbar [ad_admin_context_bar "index.tcl {[ad_parameter SystemName fs]}" "group.tcl?group_id=$group_id \"$group_name\"" "$return_url" "$title"]
} else {
    set user_id [db_string unused "select owner_id from fs_files where file_id=:file_id"]
    set personal_name [db_string unused "select first_names||' '||last_name from users where user_id=:user_id"]
    append personal_name "'s Files"
    set navbar [ad_admin_context_bar "index.tcl {[ad_parameter SystemName fs]}" "personal-space.tcl?owner_id=$user_id \"$personal_name\""  "$return_url" "$title"]
    set group_id ""
}

set html "[ad_admin_header $title]

<h2>$title</h2>

$navbar

<hr>
<form method=POST action=file-edit-2>

[export_form_vars file_id return_url group_id]

<table>
<tr>
<td valign=top align=right>$object_type Title: </td>
<td><input size=30 name=file_title value=\"$file_title\"></td>
</tr>
<tr>
<td valign=top align=right>Location:</td>
<td>[fs_folder_selection $owner_id $group_id $public_p $file_id]</td>
</tr>
<tr>
<td align=right>Severe actions:</td>
<td><a href=file-delete?[export_url_vars group_id file_id return_url object_type]>Delete this $object_type</a> and all of it's versions.
<tr>
<td></td>
<td><input type=submit value=\"Update\">
</td>
</tr>
</table>

</form>

[ad_admin_footer]
"

doc_return  200 text/html $html

