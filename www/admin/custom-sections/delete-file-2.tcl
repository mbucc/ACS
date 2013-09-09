# /www/admin/custom-sections/delete-file-2.tcl
ad_page_contract {
    Purpose:  deletes a custom section page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author ahmeds@arsdigita.com
    @creation-date  12/30/99

    @param content_file_id
    @param section_id
    @param confirm_deletion

    @cvs-id delete-file-2.tcl,v 3.2.2.6 2000/07/28 22:21:27 lutter Exp
} {
    content_file_id:integer
    section_id:integer
    confirm_deletion
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

if { $confirm_deletion =="yes" } {
    db_dml custom_sections_delete_content "
    delete from content_files 
 where content_file_id = :content_file_id 
"
}

db_release_unused_handles

ad_returnredirect "index?[export_url_vars section_id]"








