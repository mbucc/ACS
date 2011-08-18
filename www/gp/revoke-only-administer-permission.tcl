#
# /www/gp/confirm-revoke.tcl
#
# created by michael@arsdigita.com, 2000-03-23
#
# Confirmation page to present before revoking a permission
# for a given row in the database.
#
# $Id: revoke-only-administer-permission.tcl,v 1.1.2.1 2000/03/23 18:44:31 michael Exp $
#

ad_page_variables {
    on_what_id
    on_which_table
    object_name
    permission_id
    return_url
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

ad_require_permission $db $user_id "administer" $on_what_id $on_which_table

ns_db releasehandle $db

ad_return_template
