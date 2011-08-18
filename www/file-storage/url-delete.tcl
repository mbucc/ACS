# /file-storage/url-delete.tcl
#
# created by aure@arsdigita.com, June, 1999
#
# modified by randyg@arsdigita.com, January, 2000 to use the 
# general permissions module
#
# $Id: url-delete.tcl,v 3.3.2.1 2000/03/24 02:35:20 aure Exp $

ad_page_variables {
    {file_id}
    {return_url}
    {group_id ""}
    {source ""}
}
 
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set title "Delete URL"
set db [ns_db gethandle ]

set exception_text ""
set exception_count 0

set version_id [database_to_tcl_string $db "
    select version_id from fs_versions_latest where file_id = $file_id"]

if ![fs_check_edit_p $db $user_id $version_id $group_id] {
    incr exception_count
    append exception_text "<li>You do not own this URL."
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set file_title [database_to_tcl_string $db "
    select file_title from fs_files where file_id = $file_id"]

if ![empty_string_p $group_id] {
    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]  $title]
} else {
    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] $title]
#    set return_url ""
}

# release the database handle

ns_db releasehandle $db

# serve the page

ns_return 200 text/html "[ad_header $title ]

<h2> $title </h2>

$navbar

<hr>

<blockquote>

Are you sure you want to delete $file_title?

<form action=url-delete-2 method=post>
[export_form_vars group_id file_id return_url source]

<input type=submit value=\"Yes, Delete!\" >

</form>

</blockquote>

[ad_footer [fs_system_owner]]"










