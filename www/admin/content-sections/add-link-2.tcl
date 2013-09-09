# /www/admin/content-sections/update/add-link-2.tcl
ad_page_contract {
    Content Section add link target page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author  ahmeds@mit.edu
    @creation-date  29/12/99
    @cvs-id add-link-2.tcl,v 3.1.6.6 2000/07/27 19:40:35 lutter Exp

    @param from_section_id
    @param to_section_id
    @param section_link_id
} {
    from_section_id:optional
    to_section_id:optional
    section_link_id:optional
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

db_dml content_insert "
insert into content_section_links
(section_link_id, from_section_id, to_section_id)
select :section_link_id, :from_section_id, :to_section_id 
 from dual 
 where not exists (select 1 
 from content_section_links 
 where section_link_id = :section_link_id) 
"

db_release_unused_handles

ad_returnredirect link.tcl
