# /www/wp/presentation-acl-delete-2.tcl

ad_page_contract {
    Removes a user's ACL.    

    @author Jon Salz <jsalz@mit.edu>
    @creation-date 28 Nov 1999

    @param presentation_id the ID of the presentation
    @param req_user_id 

    @cvs-id presentation-acl-delete-2.tcl,v 3.1.6.8 2000/08/16 21:49:40 mbryzek Exp
} {
    presentation_id:naturalnum,notnull
    req_user_id:naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row group_id_select "
select group_id
from wp_presentations where presentation_id = :presentation_id" 

db_dml group_map_delete "delete from user_group_map where group_id = :group_id and user_id = :req_user_id"

db_release_unused_handles

ad_returnredirect "presentation-acl?presentation_id=$presentation_id"
