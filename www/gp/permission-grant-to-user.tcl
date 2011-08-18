#
# /gp/permission-grant-to-user.tcl
#
# created by michael@arsdigita.com, 2000-02-27
#
# $Revision: 3.2 $
# $Date: 2000/03/02 08:20:24 $
# $Author: michael $
#

ad_page_variables {
    on_what_id
    on_which_table
    object_name
    return_url
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

ad_require_permission $db $user_id "administer" $on_what_id $on_which_table

ns_db releasehandle $db

set passthrough {on_what_id on_which_table object_name return_url}

ad_return_template
