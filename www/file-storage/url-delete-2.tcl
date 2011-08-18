# /file-storage/url-delete-2.tcl
#
# by aure@arsdigita.com, July 1999
#
# marks a file deleted (but does not actually remove anything 
# from the database); if a folder, marks the entire subtree deleted
#
# modified by randyg@arsdigita.com, January, 2000 to use the 
# general permissions module
#
# $Id: url-delete-2.tcl,v 3.2.2.2 2000/04/28 15:10:28 carsten Exp $

ad_page_variables {
    {file_id}
    {group_id ""}
    {return_url}
    {source ""}
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# Determine if we are working in a Group, or our personal space
# this is based if no group_id was sent - then we are in
# our personal area - otherwise the group defined by group_id

set exception_text ""
set exception_count 0

if [empty_string_p $file_id] {
    incr exception_count
    append exception_text "<li>No file was specified"
}

set version_id [database_to_tcl_string $db "
    select version_id from fs_versions_latest where file_id = $file_id"]

if {! [fs_check_edit_p $db $user_id $version_id $group_id]} {
    incr exception_count
    append exception_text "<li>You do not own this file"
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

ns_db dml $db "update fs_files set deleted_p = 't' where file_id = $file_id"

if {[info exists group_id] && ![empty_string_p $group_id]} {
    ad_returnredirect group?group_id=$group_id
} else {
    ad_returnredirect /file-storage/$source
}
