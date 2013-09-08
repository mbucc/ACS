# www/admin/portals/delete-manager-2.tcl

ad_page_contract {
    delete a super user from the portals system

    @author aure@arsdigita.com
    @author dh@arsdigita.com
    @creation-date 10/8/1999    
    @cvs-id delete-manager-2.tcl,v 3.2.2.6 2000/07/21 03:57:52 ron Exp
} {
    {admin_id:integer,optional}
}

if {![info exists admin_id]} {
    ad_returnredirect index.tcl
    return
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set group_id [db_string super_admin_group_id "select group_id 
    from user_groups
    where group_name = 'Super Administrators'
    and group_type = 'portal_group'"]

# delete the administrator
db_dml user_group_map_delete "
    delete from user_group_map
    where  user_id = :admin_id
    and    group_id = :group_id
    and    role='administrator'"

db_release_unused_handles

ad_returnredirect index.tcl

