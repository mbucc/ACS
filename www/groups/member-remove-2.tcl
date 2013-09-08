
ad_page_contract {
    @param group_id the ID of the group
    @param user_id the user to remove
    @param return_url the URL to send the user to afterwards

    @cvs-id member-remove-2.tcl,v 3.3.6.4 2000/07/24 20:16:27 ryanlee Exp
} {
    group_id:notnull,naturalnum
    user_id:notnull,naturalnum
    {return_url "index"}
}

set mapping_user [ad_verify_and_get_user_id]

if { ![ad_user_group_authorized_admin_or_site_admin $mapping_user $group_id] } {
    ad_return_error "Permission Denied" "You do not have permission to remove a member from this group."
    return
}

db_dml delete_from_ugm "delete from user_group_map where
user_id = :user_id and group_id = :group_id"

db_release_unused_handles

ad_returnredirect $return_url




