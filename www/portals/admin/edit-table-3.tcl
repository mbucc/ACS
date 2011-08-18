#
# /portals/admin/edit-table-3.tcl
#
# updates the database with edited table information and redirects back to originating page
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999# edit-table-3.tcl
#
# $Id: edit-table-3.tcl,v 3.0.4.2 2000/04/28 15:11:17 carsten Exp $

#ad_page_variables {table_name adp table_id group_id admin_url}
set_the_usual_form_variables
# table_name, adp, table_id, maybe group_id, admin_url

set db [ns_db gethandle]

# -------------------------------------
# verify user and set up possible context bar
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id] || [empty_string_p $group_id]} {
    set group_id ""
    set return_url index.tcl
    set context_bar "[ad_context_bar [list /portals/ "Portals"] [list index.tcl "Administration"] [list edit-table.tcl?table_id=$table_id "Edit Table"] "Error"]"
} else {
    set context_bar ""
}
portal_check_administrator_maybe_redirect $db $user_id $group_id
#-------------------------------------

if {![info exists admin_url] || [empty_string_p $admin_url]} {
    set admin_url_sql "admin_url = null"
} else {
    set admin_url_sql "admin_url = '$QQadmin_url'"
}

# --------------------------------------- 
# disallow table creation if table_name or adp is blank
if {[empty_string_p [string trim $table_name]] || [empty_string_p [string trim $adp]] } {
  
    # get generic display info
    portal_display_info

    ns_return 200 text/html "
    [portal_admin_header "Error"]
    $context_bar
    <hr>$font_tag
    Neither table name nor its HTML/ADP may be blank.
    [portal_admin_footer]"
    
    return
}
#----------------------------------------

# update table data
ns_ora clob_dml $db "
update portal_tables
set table_name = '$QQtable_name',
    adp = empty_clob(),
    creation_user = $user_id,
    modified_date = sysdate,
    $admin_url_sql
where table_id = $table_id
returning adp into :one" $adp

# flush memoization of pages with this table, done with foreach since the dbhandle must be released

set group_list [database_to_tcl_list_list $db  "
select page_number, group_id
from portal_table_page_map map, portal_pages p
where table_id=$table_id 
and map.page_id=p.page_id
and group_id is not null"]

ns_db releasehandle $db

foreach pair $group_list {
    set page_number [lindex $pair 0]
    set new_group_id [lindex $pair 1]
    util_memoize_flush "portal_display_page $new_group_id $page_number group"
}

# redirect user 
if  {![empty_string_p $group_id]} {
    ns_return 200 text/html "<script>
    <!--
    self.window.close()
    //-->
    </script>"
} else {
    ad_returnredirect index.tcl
}



