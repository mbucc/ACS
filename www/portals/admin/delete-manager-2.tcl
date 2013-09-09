# www/portals/admin/delete-manager-2.tcl

ad_page_contract {
    Actually remove a given manager from the given group.
    
    @author Aure aure@arsdigita.com 
    @author Dave Hill dh@arsdigita.com
    @param group_id
    @param admin_id
    @cvs-id delete-manager-2.tcl,v 3.3.2.5 2000/07/21 04:03:28 ron Exp
} {
    {group_id:naturalnum,notnull}
    {admin_id:naturalnum,notnull}
}

if {![info exists group_id] || ![info exists admin_id]} {
    ad_returnredirect index
    return
}



# ---------------------------------
# verify user

set user_id [ad_verify_and_get_user_id]
portal_check_administrator_maybe_redirect $user_id

# ---------------------------------

# delete the manager

db_dml portals_delete_manager_2 "
    delete from user_group_map
    where  user_id = :admin_id
    and    group_id = :group_id
    and    role = 'administrator'"

db_release_unused_handles

ad_returnredirect index

