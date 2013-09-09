# /www/admin/content-sections/toggle-enabled-p.tcl

ad_page_contract {
    Toggles enabled_p column of the section

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author tarik@arsdigita.com
    @creation-date 22/12/99 

    @cvs-id toggle-enabled-p.tcl,v 3.1.6.6 2000/07/27 19:47:29 lutter Exp

    @param section_key
} {
    section_key:notnull
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

db_dml update_content_sections "
update content_sections 
 set enabled_p = logical_negation(enabled_p) where 
 [ad_scope_sql] and section_key = :section_key 
" 

db_release_unused_handles

ad_returnredirect index

