# /file-storage/url-edit-2.tcl

ad_page_contract {
    updates information for an URL and then recalculates order

    @author Mark Dettinger <dettinger@arsdigita.com>
    @creation-date May 2000
    @cvs-id url-edit-2.tcl,v 1.1.2.1 2000/07/25 05:36:53 bquinn Exp
} {
    {file_id:naturalnum}
    {file_title}
    {return_url}
    {group_id:naturalnum ""}
    {parent_id:naturalnum}
    {object_type}
}


set user_id [ad_maybe_redirect_for_registration]

# check the user input first

set exception_text ""
set exception_count 0

if [empty_string_p $file_title] {
    append exception_text "<li>You must give a title to the URL\n"
    incr exception_count
}

if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

db_transaction {
    db_dml url_update {  
	update fs_files
	set    file_title = :file_title,
               parent_id  = :parent_id
	where  file_id = :file_id
    }
    fs_order_files
}

db_release_unused_handles
ad_returnredirect $return_url
