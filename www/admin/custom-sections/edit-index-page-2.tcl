# /www/admin/custom-sections/edit-index-page-2.tcl
ad_page_contract {
    Purpose:  edits custom section index page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author  ahmeds@arsdigita.com
    @creation-date  12/30/99

    @param section_id
    @param body   Body of file (text or html)
    @param html_p "t" if html, "f" otherwise

    @cvs-id edit-index-page-2.tcl,v 3.2.2.7 2000/07/28 22:22:53 lutter Exp
} {
    section_id:integer,notnull
    body:allhtml
    html_p
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set exception_count 0
set exception_text ""

if [catch { 
    db_dml custom_sections_content_section_insert "
    update content_sections
    set html_p = '$html_p',
    body = empty_clob()
    where section_id= $section_id
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

ad_returnredirect index?[export_url_vars section_id]



