# /gp/permission-grant-to-user-2.tcl
#

ad_page_contract {
    @author michael@arsdigita.com
    @creation-date 2000-02-27
    @cvs-id permission-grant-to-user-2.tcl,v 3.2.10.4 2000/07/21 04:00:11 ron Exp
} {
    user_id_from_search:integer,notnull
    first_names_from_search:notnull
    last_name_from_search:notnull
    email_from_search:notnull
    on_what_id:integer,notnull
    on_which_table:notnull
    object_name:notnull
    return_url:notnull
}


set user_id [ad_verify_and_get_user_id]


ad_require_permission $user_id "administer" $on_what_id $on_which_table

db_release_unused_handles

set full_name "$first_names_from_search $last_name_from_search"
set scope "user"

ad_return_template
