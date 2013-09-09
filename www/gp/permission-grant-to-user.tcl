# /gp/permission-grant-to-user.tcl

ad_page_contract {
    @author michael@arsdigita.com,
    @creation-date 2000-02-27
    @cvs-id permission-grant-to-user.tcl,v 3.2.10.5 2000/07/21 04:00:11 ron Exp
} {
    on_what_id:naturalnum,notnull
    on_which_table:notnull
    object_name:notnull
    return_url:notnull
}


set user_id [ad_verify_and_get_user_id]


ad_require_permission $user_id "administer" $on_what_id $on_which_table

db_release_unused_handles

set passthrough {on_what_id on_which_table object_name return_url}

ad_return_template
