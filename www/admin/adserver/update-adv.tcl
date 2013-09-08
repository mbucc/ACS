# /www/admin/adserver/update-adv.tcl

ad_page_contract {
    @param target_url
    @param track_clickthru_p
    @param adv_filename 
    @param local_image_p
    @param adv_key:notnull

    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id update-adv.tcl,v 3.2.2.5 2000/11/20 23:55:20 ron Exp
} {
    target_url 
    track_clickthru_p
    adv_filename 
    local_image_p
    adv_key:notnull
}

db_dml adv_update_query "update advs set 
target_url = :target_url, 
track_clickthru_p = :track_clickthru_p, 
adv_filename = :adv_filename, 
local_image_p = :local_image_p 
where adv_key = :adv_key"

db_release_unused_handles

ad_returnredirect one-adv.tcl?[export_url_vars adv_key]





