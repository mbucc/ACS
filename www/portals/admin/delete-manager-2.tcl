#
# /portals/admin/delete-manager-2.tcl
#
# deletes a manager from a portal group
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: delete-manager-2.tcl,v 3.0.4.2 2000/04/28 15:11:17 carsten Exp $
#

ad_page_variables {group_id admin_id}

if {![info exists group_id] || ![info exists admin_id]} {
    ad_returnredirect index
    return
}

set db [ns_db gethandle]

# ---------------------------------
# verify user

set user_id [ad_verify_and_get_user_id]
portal_check_administrator_maybe_redirect $db $user_id

# ---------------------------------

# delete the manager
ns_db dml $db "
    delete from user_group_map
    where  user_id = $admin_id
    and    group_id = $group_id
    and    role = 'administrator'"

ad_returnredirect index















