# $Id: add-manager-2.tcl,v 3.1.2.1 2000/04/28 15:09:16 carsten Exp $
# add-manager-2.tcl
#
# adds a person to the list of super administrators 
# 
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999

set_the_usual_form_variables
# user_id_from_search
# first_names_from_search
# last_names_from_search
# email_from_search


set db [ns_db gethandle]
# get group_id for super users
set group_id [database_to_tcl_string $db "select group_id 
    from user_groups
    where group_name = 'Super Administrators'
    and group_type = 'portal_group'"]


set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration 

# check if this person is already an administrator of this group
set check_result [database_to_tcl_string $db "select decode ( ad_user_has_role_p ( $user_id_from_search, $group_id, 'administrator' ), 'f', 0, 1 ) from dual"]

if { $check_result == 0 } {
    ns_db dml $db "
        insert into user_group_map
        (user_id, group_id, role, mapping_user, mapping_ip_address)
        values
        ($user_id_from_search, $group_id, 'administrator', $user_id, '[ns_conn peeraddr]') "
}

ad_returnredirect index.tcl
