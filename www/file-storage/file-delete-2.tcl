# /file-storage/file-delete-2.tcl
#
# by aure@arsdigita.com, July 1999
#
# marks a file deleted (but does not actually remove anything 
# from the database); if a folder, marks the entire subtree deleted
#
# modified by randyg@arsdigita, January, 2000 to use the general permissions module
#
# $Id: file-delete-2.tcl,v 3.2.2.3 2000/04/28 15:10:27 carsten Exp $

ad_page_variables {
    {file_id}
    {group_id ""}
    {source ""}
}

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set db [ns_db gethandle ]
# Determine if we are working in a Group, or our personal space
# this is based if no group_id was sent - then we are in
# our personal area - otherwise the group defined by group_id

set exception_text ""
set exception_count 0

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


# is this a folder ? Get all its children
set folder_p [database_to_tcl_string $db "
    select folder_p from fs_files where file_id=$file_id"]

ns_db dml $db "begin transaction"

if {$folder_p=="t"} {

    set children_query "
        select file_id
        from   fs_files
        connect by prior file_id = parent_id
        start with file_id = $file_id"

    # note that the "children" list includes the top-level folder
    set children_list [database_to_tcl_list $db $children_query]
    
    set sql_faux_delete "
        update fs_files
        set    deleted_p = 't'
        where  file_id in ( [join $children_list ", "] ) "
    
    
} else {
    set sql_faux_delete "
        update fs_files
        set    deleted_p = 't'
        where  file_id = $file_id"
}


ns_db dml $db $sql_faux_delete

fs_order_files $db

ns_db dml $db "end transaction"

ns_db releasehandle $db 

if {[info exists group_id] && ![empty_string_p $group_id]} {
    ad_returnredirect group?group_id=$group_id
} else {
    ad_returnredirect /file-storage/$source
}
