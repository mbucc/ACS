# $Id: delete-manager-2.tcl,v 3.0.4.1 2000/04/28 15:09:16 carsten Exp $
# delete-manager-2.tcl
#
# delete a super user from the portals system
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999

set_the_usual_form_variables 
#  admin_id


if {![info exists admin_id]} {
    ad_returnredirect index.tcl
    return
}


set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set group_id [database_to_tcl_string $db "select group_id 
    from user_groups
    where group_name = 'Super Administrators'
    and group_type = 'portal_group'"]


# delete the administrator
ns_db dml $db "
    delete from user_group_map
    where  user_id=$admin_id
    and    group_id=$group_id
    and    role='administrator'"

ad_returnredirect index.tcl


