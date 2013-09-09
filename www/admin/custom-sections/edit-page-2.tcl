# /www/admin/custom-sections/edit-page-2.tcl
ad_page_contract {
    Edits custom section page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author ahmeds@arsdigita.com
    @creation-date  12/30/99

    @param content_file_id
    @param section_id
    @param content_file_id
    @param page_pretty_name
    @param body
    @param html_p

    @cvs-id edit-page-2.tcl,v 3.2.2.5 2000/07/28 22:24:15 lutter Exp
} {
    content_file_id:integer,notnull
    section_id:integer,notnull
    page_pretty_name:notnull
    body:allhtml
    html_p:notnull
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

if [catch { 
    db_dml "cs_update_content_files" "
    update content_files
    set page_pretty_name=:page_pretty_name,
    html_p = :html_p,
    body = empty_clob()
    where content_file_id=:content_file_id
    returning body
    into :1" -clobs [list $body]
} errmsg] {
    db_release_unused_handles
    incr exception_count
    append exception_text "
    <li>Error occured while inserting data into database. Oracle returned error:
    <br>$errmsg
    "
    ad_scope_return_complaint $exception_count $exception_text
    return
} 

db_release_unused_handles

ad_returnredirect index.tcl?[export_url_vars section_id]





