# /file-storage/url-delete-2.tcl

ad_page_contract {
    marks a file deleted (but does not actually remove anything 
    from the database); if a folder, marks the entire subtree deleted

    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id url-delete-2.tcl,v 3.7.2.2 2000/07/21 22:05:17 mdetting Exp

    modified by randyg@arsdigita.com, January, 2000 to use the 
    general permissions module
} {
    {file_id}
    {ower_id ""}
    {group_id ""}
    {return_url}
    {source ""}
}

set user_id [ad_maybe_redirect_for_registration]

# Determine if we are working in a Group, or our personal space
# this is based if no group_id was sent - then we are in
# our personal area - otherwise the group defined by group_id

set exception_text ""
set exception_count 0

if [empty_string_p $file_id] {
    incr exception_count
    append exception_text "<li>No file was specified"
}

set version_id [db_string version "
    select version_id from fs_versions_latest where file_id = :file_id"]

if {! [fs_check_edit_p $user_id $version_id $group_id]} {
    incr exception_count
    append exception_text "<li>You do not own this file"
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

db_dml url_delete "update fs_files set deleted_p = 't' where file_id = :file_id"

db_release_unused_handles

switch $source {
    "private_individual" {
	set return_url "private-one-person?[export_url_vars owner_id]"
    }
    "private_group" { 
	set return_url "private-one-group?[export_url_vars group_id]"
    }
    "public_individual" {
	set return_url "public-one-person?[export_url_vars owner_id]"
    }
    "public_group" {
	set return_url "public-one-group?[export_url_vars group_id]"
    }
    default {
	set return_url ""
    }
}

ad_returnredirect $return_url
