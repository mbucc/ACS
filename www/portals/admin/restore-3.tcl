#
# /portals/admin/restore-3.tcl
#
# restores version of a table from the audit table into active portal_tables
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: restore-3.tcl,v 3.0.4.2 2000/04/28 15:11:18 carsten Exp $
#

#ad_page_varibles {audit_id}
set_the_usual_form_variables
# audit_id

set db [ns_db gethandle]

# -------------------------------
# verify the user
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    set group_id ""
}
portal_check_administrator_maybe_redirect $db $user_id $group_id
# -------------------------------

set table_id [database_to_tcl_string $db "select table_id from portal_tables_audit  where audit_id = $audit_id"]
set count [database_to_tcl_string $db "select count(*) from portal_tables where table_id=$table_id"]

if {$count > 0 } {
    # restoring an old version of a current portal table
    ns_db dml $db "update portal_tables
    set (table_name, adp, admin_url, modified_date, creation_user) = 
    (select table_name, adp, admin_url, modified_date, creation_user from portal_tables_audit where audit_id = $audit_id) 
    where table_id = $table_id"
} else {
    # restoring a deleted table
    ns_db dml $db "insert into portal_tables
    (table_id, table_name, adp, admin_url, modified_date, creation_user)
    select table_id, table_name, adp, admin_url, modified_date, creation_user from portal_tables_audit where audit_id = $audit_id"
} 
 
# flush memoization of pages with this table, 
# done with foreach since the dbhandle must be released

set group_list [database_to_tcl_list_list $db  "
    select page_number, group_id
    from   portal_table_page_map map, portal_pages p
    where  table_id=$table_id 
    and    map.page_id=p.page_id
    and    group_id is not null"]

ns_db releasehandle $db

foreach pair $group_list {
    set page_number [lindex $pair 0]
    set new_group_id [lindex $pair 1]
    util_memoize_flush "portal_display_page $new_group_id $page_number group"
}

if  {![empty_string_p $group_id]} {
    ns_return 200 text/html "<script>
    <!--
    self.window.close()
    //-->
    </script>"
} else {
    ad_returnredirect index.tcl
}


