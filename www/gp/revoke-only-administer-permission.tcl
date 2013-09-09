# /www/gp/confirm-revoke.tcl
#

ad_page_contract {
    @author michael@arsdigita.com
    @creation-date 2000-03-23
    @cvs-id revoke-only-administer-permission.tcl,v 3.1.8.4 2000/07/21 04:00:13 ron Exp

    Confirmation page to present before revoking a permission
    for a given row in the database.
} {
    on_what_id:integer,notnull
    on_which_table:notnull
    object_name:notnull
    permission_id:integer,notnull
    return_url:notnull
}


set user_id [ad_verify_and_get_user_id]


ad_require_permission $user_id "administer" $on_what_id $on_which_table

db_release_unused_handles

ad_return_template
