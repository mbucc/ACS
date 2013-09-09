# /www/gp/permission-revoke.tcl

ad_page_contract {
    Revokes the permission for someone given administrator permissions, only directed here if the last administrator is being revoked.
	    
    @author michael@arsdigita.com
    @creation-date 2000-03-23
    @cvs-id permission-revoke.tcl,v 3.2.6.7 2000/07/26 18:47:48 jwong Exp
} {
    on_what_id:integer,notnull
    on_which_table:notnull
    permission_id:integer,notnull
    return_url:notnull
}


set user_id [ad_verify_and_get_user_id]

ad_require_permission $user_id "administer" $on_what_id $on_which_table

db_transaction {
db_dml gp_permission_revoke "begin
 ad_general_permissions.revoke_permission($permission_id);
end;"
} on_error {
    db_release_unused_handles
    ad_return_error "Error" "Couldn't revoke the permission for user $on_what_id."
}
    
db_release_unused_handles

ad_returnredirect $return_url
