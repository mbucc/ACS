# /www/custom-sections/file/get-binary-file.tcl
ad_page_contract {
    This serves a custom section image 

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date    12/28/99

    @param content_file_id

    @cvs-id get-binary-file.tcl,v 3.1.2.5 2000/07/28 20:52:20 lutter Exp
} {
    content_file_id:integer
}

ad_scope_error_check
ad_scope_authorize $scope all all none

set mime_type [db_string custom_select_file_type "
select file_type 
 from content_files 
 where content_file_id = :content_file_id 
"]

db_release_unused_handles

ReturnHeaders $mime_type

db_write_blob custom_show_binary_data "
select binary_data 
 from content_files 
 where content_file_id = $content_file_id 
"







