#
# /portals/admin/add-manager-2.tcl
#
# insert the user as a portal manager
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: add-manager-2.tcl,v 3.1.2.3 2000/04/28 15:11:16 carsten Exp $
#

ad_page_variables {
	group_id 
	user_id_from_search
	first_names_from_search 
	last_name_from_search
 	email_from_search
} 

if {![info exists group_id]} {
    ad_returnredirect index
    return
}

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]
portal_check_administrator_maybe_redirect $db $user_id

# check if this person is already an administrator of this group
set check_result [database_to_tcl_string $db "
    select decode ( ad_user_has_role_p ( $user_id_from_search, $group_id, 'administrator' ), 'f', 0, 1 ) from dual"]

if { $check_result == 0 } {
    ns_db dml $db "
        insert into user_group_map
        (user_id, group_id, role, mapping_user, mapping_ip_address)
        values
        ($user_id_from_search, $group_id, 'administrator',$user_id, '[ns_conn peeraddr]') "
}

ad_returnredirect index











