# /www/admin/content-sections/update/delete-link.tcl
ad_page_contract {
    Content Section delete link target page 

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @creation-date 29/12/99
    @author ahmeds@mit.edu

    @cvs-id delete-link.tcl,v 3.1.6.7 2000/07/27 19:33:48 lutter Exp

    @param from_section_id
    @param to_section_id
} {
    from_section_id:notnull
    to_section_id:notnull
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

db_dml delete_link "
delete from content_section_links 
 where from_section_id = :from_section_id 
 and to_section_id = :to_section_id"

db_release_unused_handles

ad_returnredirect link

