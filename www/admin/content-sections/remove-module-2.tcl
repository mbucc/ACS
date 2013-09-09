# /www/admin/content-sections/update/remove-module-2.tcl

ad_page_contract {
    Removes association between module and the group

    Scope aware. Group scope only. Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author tarik@arsdigita.com
    @creation-date 01/01/2000
    @cvs-id remove-module-2.tcl,v 3.2.2.5 2000/07/27 19:43:52 lutter Exp

    @param section_key
    @param confirm_button
} {
    section_key:notnull
    confirm_button:notnull
}

ad_scope_error_check
ad_scope_authorize $scope none group_admin none

if { [string compare $confirm_button yes]!=0 } {
    ad_returnredirect "content-section-edit?[export_url_vars section_key]"
    return
}

db_transaction {

db_dml remove_content_section_link "
delete from content_section_links
where from_section_id=(select section_id 
 from content_sections 
 where scope = 'group' 
 and group_id = :group_id 
 and section_key = :section_key) 
 or to_section_id = (select section_id 
 from content_sections 
 where scope = 'group' 
 and group_id = :group_id 
 and section_key = :section_key) 
"

db_dml remove_content_file "
delete from content_files
where section_id=(select section_id 
 from content_sections 
 where scope = 'group' 
 and group_id = :group_id 
 and section_key = :section_key) 
"

db_dml remove_content_section "
delete from content_sections 
 where scope = 'group' 
 and group_id = :group_id 
 and section_key = :section_key 
"

}

db_release_unused_handles

ad_returnredirect index
