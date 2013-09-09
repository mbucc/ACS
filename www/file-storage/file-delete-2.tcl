# /file-storage/file-delete-2.tcl
ad_page_contract {
    marks a file deleted (but does not actually remove anything 
    from the database); if a folder, marks the entire subtree deleted
    
    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id file-delete-2.tcl,v 3.8.2.2 2000/07/21 22:05:16 mdetting Exp

    modified by randyg@arsdigita, January, 2000 to use the general permissions module
} {
    {file_id}
    {group_id ""}
    {source ""}
}

set user_id [ad_maybe_redirect_for_registration]

# Determine if we are working in a Group, or our personal space
# this is based if no group_id was sent - then we are in
# our personal area - otherwise the group defined by group_id

set exception_text ""
set exception_count 0

set version_id [db_string unused "
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

# is this a folder ? Get all its children
set folder_p [db_string unused "
    select folder_p from fs_files where file_id=:file_id"]

db_transaction {

if {$folder_p=="t"} {

    set children_query "
        select file_id
        from   fs_files
        connect by prior file_id = parent_id
        start with file_id = :file_id"

    # note that the "children" list includes the top-level folder
    set children_list [db_list unused $children_query]
    
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

db_dml unused $sql_faux_delete

fs_order_files

}

db_release_unused_handles 

switch $source {
    "private_individual" {
	set return_url "private-one-person?[export_url_vars user_id]"
    }
    "private_group" { 
	set return_url "private-one-group?[export_url_vars group_id]"
    }
    "public_individual" {
	set return_url "public-one-person?[export_url_vars user_id]"
    }
    "public_group" {
	set return_url "public-one-group?[export_url_vars group_id]"
    }
    default {
	set return_url ""
    }
}

ad_returnredirect $return_url
