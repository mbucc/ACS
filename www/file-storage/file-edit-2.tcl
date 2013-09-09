# /file-storage/file-edit-2.tcl

ad_page_contract {
    updates information for a file and then recalculates order

    @author dh@arsdigita.com
    @creation-date July 1999

    modified by randyg@arsdigita.com January 2000 to use the general permissions system
} {
    {file_id}
    {file_title}
    {version_id ""}
    {return_url}
    {group_id ""}
    {parent_id}
    {object_type}
    {file_type ""}
}

set user_id [ad_maybe_redirect_for_registration]

# check the user input first

set exception_text ""
set exception_count 0

if [empty_string_p $version_id] {
    incr exception_count
    append exception_text "<li>You must provide a version for this file you wish to update."
} elseif {![fs_check_edit_p $user_id $version_id $group_id]} {
    incr exception_count
    append exception_text "<li>You do not own this file"
}

if [empty_string_p $file_title] {
    append exception_text "<li>You must give a title to the file\n"
    incr exception_count
}

if { $object_type == "File" && (![info exists file_type] || [empty_string_p $file_type]) } {
    append exception_text "<li>You cannot leave the type unspecified.\n"
    incr exception_count
}

if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set public_p [db_string permission "select ad_general_permissions.user_has_row_permission_p ( :user_id, 'read', :version_id, 'FS_VERSIONS' ) from dual"]

db_transaction {

    db_dml file_info_update {
	update fs_files
	set    file_title = :file_title,
	       parent_id = :parent_id
	where  file_id = :file_id
    }

    if { [info exists object_type] && $object_type == "File" && [info exists file_type] && ![empty_string_p $file_type] } {

	db_dml unused {
	    update fs_versions
	    set    file_type = :file_type
	    where  file_id = :file_id
	    and    superseded_by_id is null
	}
    }
    fs_order_files   
}

db_release_unused_handles

ad_returnredirect $return_url


