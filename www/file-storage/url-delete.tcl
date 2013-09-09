# /file-storage/url-delete.tcl
ad_page_contract {
    @author aure@arsdigita.com
    @creation-date June, 1999
    @cvs-id url-delete.tcl,v 3.7.2.4 2000/09/22 01:37:49 kevin Exp

    modified by randyg@arsdigita.com, January, 2000 to use the 
    general permissions module
} {
    {file_id:integer}
    {return_url}
    {owner_id ""}
    {group_id ""}
    {source ""}
}

set user_id [ad_maybe_redirect_for_registration]

set title "Delete URL"

set exception_text ""
set exception_count 0

set version_id [db_string version "
    select version_id from fs_versions_latest where file_id = :file_id"]

if ![fs_check_edit_p $user_id $version_id $group_id] {
    incr exception_count
    append exception_text "<li>You do not own this URL."
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set file_title [db_string files "
    select file_title from fs_files where file_id = :file_id"]

if ![empty_string_p $group_id] {
    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]  $title]
} else {
    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] $title]
#    set return_url ""
}

# serve the page

doc_return  200 text/html "[ad_header $title ]

<h2> $title </h2>

$navbar

<hr align=left>

<blockquote>

Are you sure you want to delete $file_title?

<form action=url-delete-2 method=post>
[export_form_vars owner_id group_id file_id return_url source]

<input type=submit value=\"Yes, Delete!\" >

</form>

</blockquote>

[ad_footer [fs_system_owner]]"
