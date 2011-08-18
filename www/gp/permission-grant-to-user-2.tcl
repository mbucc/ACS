#
# /gp/permission-grant-to-user-2.tcl
#
# created by michael@arsdigita.com, 2000-02-27
#
# $Revision: 3.2 $
# $Date: 2000/03/02 08:20:24 $
# $Author: michael $
#

ad_page_variables {
    user_id_from_search
    first_names_from_search
    last_name_from_search
    email_from_search
    on_what_id
    on_which_table
    object_name
    return_url
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

ad_require_permission $db $user_id "administer" $on_what_id $on_which_table

ns_db releasehandle $db

set full_name "$first_names_from_search $last_name_from_search"
set scope "user"

ad_return_template
