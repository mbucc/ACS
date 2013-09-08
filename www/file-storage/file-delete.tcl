# /file-storage/file-delete.tcl
ad_page_contract {
    this page makes sure that a user wants to delete a file or a folder.  
    If a folder is deleted, all of the children are also deleted.

    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id file-delete.tcl,v 3.4.6.5 2000/09/22 01:37:47 kevin Exp

    modified by randyg@arsidgita.com, January, 2000 to use the general permissions system
} { 
    {file_id:integer}
    {object_type}
    {return_url}
    {group_id ""}
    {source ""}
}
set user_id [ad_maybe_redirect_for_registration]

set title "Delete $object_type"

set exception_text ""
set exception_count 0

if [empty_string_p $file_id] {
    incr exception_count
    append exception_text "<li>No file was specified"
}

set version_id [db_string unused "
    select version_id from fs_versions_latest where file_id = :file_id"]

if {! [fs_check_edit_p $user_id $version_id $group_id]} {
    incr exception_count
    append exception_text "<li>You do not own this file $user_id $version_id $group_id [ad_g_write_p [ad_g_permissions_id $version_id FS_VERSIONS] $user_id]"
}

if [empty_string_p $object_type] {
    incr exception_count 
    incr exception_text "<li>This page may only be accessed from the edit page"
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set file_title [db_string unused "
    select file_title from fs_files where file_id=:file_id"]

set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] $title]

set page_content "[ad_header $title ]

<h2> $title </h2>

$navbar

<hr align=left>

<blockquote>"

set number_of_children 0

# if this is a folder - get the number of childern
if {$object_type=="Folder"} {
    set sql_child_count "
        select count(*)-1
        from   fs_files
        connect by prior file_id = parent_id
        start with file_id = :file_id"
    set number_of_children [db_string unused $sql_child_count]
    append page_content "This folder has $number_of_children sub-folders/files. <p>"
}

if {$number_of_children > 0} {
    append page_content "
    Are you sure you want to delete $file_title and all of it sub-folders/files?"
} else {
    append page_content "
     Are you sure you want to delete $file_title?"
}

append page_content "
<form action=$return_url method=post>
<input type=submit value=\"No, Don't Delete\" >
</form>

<form action=file-delete-2 method=post>
[export_form_vars group_id file_id source]
<input type=submit value=\"Yes, Delete!\" >
</form>

</blockquote>
[ad_footer [fs_system_owner]]"

# serve the page

doc_return  200 text/html $page_content

