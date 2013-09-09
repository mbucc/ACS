# /www/admin/custom-sections/add-page-2.tcl
ad_page_contract {
    Purpose:  adds custom section page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date    12/30/99

    @param section_id
    @param file_name
    @param page_pretty_name
    @param body
    @param html_p
    @param content_file_id
    
    @cvs-id add-page-2.tcl,v 3.2.2.8 2001/01/10 17:12:05 khy Exp
} {
    section_id:integer
    file_name:notnull,trim
    page_pretty_name:notnull,trim
    body:allhtml
    html_p
    content_file_id:integer,verify
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

if { [regexp {[^A-Za-z0-9_\.\-]} $file_name garbage] } {
    ad_scope_return_complaint 1 "<li>Filename must be only alphanumeric characters with underscores, spaces not permitted"
    return
}

if [catch { 

    db_dml cs_clob_insert "
    insert into content_files
    (content_file_id, section_id, file_name, file_type, page_pretty_name, body, html_p)
    values
    (:content_file_id, :section_id, :file_name, 'text/html', :page_pretty_name, empty_clob(), :html_p)
    returning body
    into :1" -clobs [list $body]
    
} errmsg] {

    set file_already_exists_p [db_string "cs_select_count" "
    select count (*) 
 from content_files 
 where section_id = :section_id 
 and file_name = :file_name 
" ]

    if { $file_already_exists_p > 0 } {
	ad_scope_return_complaint 1 "
	<li>File $file_name already exists. Please choose another name for your file."
    } else {
	ad_scope_return_complaint 1 "
	<li>Error occured while inserting data into database. Oracle returned error:
	<br>$errmsg\n"
    }
    return
} 
db_release_unused_handles

ad_returnredirect index.tcl?[export_url_vars section_id]

