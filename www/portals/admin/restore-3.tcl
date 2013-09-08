# www/portals/admin/restore-3.tcl

ad_page_contract {
    restores version of a table from the audit table into active portal_tables
    
    @param audit_id: the id of the table to be restored, in the audit table.
    @author Aure aure@arsdigita.com 
    @author Dave Hill dh@arsdigita.com
    @cvs-id restore-3.tcl,v 3.4.2.5 2000/09/22 01:39:04 kevin Exp
} {
    {audit_id:naturalnum,notnull}
}

# -------------------------------
# verify the user
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    set group_id ""
}
portal_check_administrator_maybe_redirect $user_id $group_id
# -------------------------------


set table_id [db_string portals_admin_restore_table_id \
        "select table_id from portal_tables_audit  where audit_id = :audit_id"]




set count [db_string portals_admin_restore_count_table_id\
        "select count(*) from portal_tables where table_id=:table_id"]


if {$count > 0 } {
    # restoring an old version of a current portal table
    db_dml portals_admin_restore_update_1 "update portal_tables
    set (table_name, adp, admin_url, modified_date, creation_user) = 
    (select table_name, 
            adp,
            admin_url, 
            modified_date,
            creation_user
             from portal_tables_audit where audit_id = :audit_id) 
    where table_id = :table_id" 
} else {
    # restoring a deleted table
    db_dml portals_admin_portal_restore_update_2 "insert into portal_tables
    (table_id, table_name, adp, admin_url, modified_date, creation_user)
    (select table_id, 
            table_name, 
            adp,
            admin_url, 
            modified_date,
            creation_user
             from portal_tables_audit where audit_id = :audit_id)" 
} 
 
# flush memoization of pages with this table, 
# done with foreach since the dbhandle must be released

set group_list [db_list_of_lists portals_admin_restore_group_list  "
    select page_number, group_id
    from   portal_table_page_map map, portal_pages p
    where  table_id=:table_id 
    and    map.page_id=p.page_id
    and    group_id is not null"]

db_release_unused_handles

foreach pair $group_list {
    set page_number [lindex $pair 0]
    set new_group_id [lindex $pair 1]
    util_memoize_flush "portal_display_page $new_group_id $page_number group"
}

if  {![empty_string_p $group_id]} {
    doc_return  200 text/html "<script>
    <!--
    self.window.close()
    //-->
    </script>"
} else {
    ad_returnredirect index
}

