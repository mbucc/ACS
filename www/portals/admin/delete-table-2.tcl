# www/portals/admin/delete-table-2.tcl

ad_page_contract {

    Deletes portal table from each portal page it appears 
    on and from the available tables

    @author aure@arsdigita.com 
    @author dh@arsdigita.com
    @param table_id
    @param group_id
    @creation-date 10/8/1999
    @cvs-id delete-table-2.tcl,v 3.2.6.5 2000/07/21 04:03:30 ron Exp
} {
    {table_id:naturalnum}
    {group_id:naturalnum,optional}
}

# -------------------------------
# verify the user
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    set group_id ""
}

portal_check_administrator_maybe_redirect $user_id $group_id
# -------------------------------

db_transaction {
    db_dml portal_admin_delete_table_page_map "delete from portal_table_page_map where table_id = :table_id"
    db_dml portal_admin_delete_portal_table "delete from portal_tables where table_id = :table_id"
} on_error {
    # No sweat, it was gone already
}

db_release_unused_handles
ad_returnredirect index





