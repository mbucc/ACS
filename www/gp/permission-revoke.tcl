#
# /www/gp/permission-revoke.tcl
#
# created by michael@arsdigita.com, 2000-03-23
#
# Revokes the specified permission and redirects to the
# specified return_url
#
# $Id: permission-revoke.tcl,v 1.1.2.2 2000/04/28 15:10:55 carsten Exp $
#

ad_page_variables {
    on_what_id
    on_which_table
    permission_id
    return_url
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

ad_require_permission $db $user_id "administer" $on_what_id $on_which_table

ns_db dml $db "begin
 ad_general_permissions.revoke_permission($permission_id);
end;"

ns_db releasehandle $db

ad_returnredirect $return_url
