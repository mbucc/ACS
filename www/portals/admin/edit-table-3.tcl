# www/portals/admin/edit-table-3.tcl

ad_page_contract {
    updates the database with edited table information and redirects back to originating page

    @author aure@arsdigita.com
    @author dh@arsdigita.com
    @param table_name
    @param adp
    @param table_id
    @param group_id
    @creation-date 10/8/1999
    @cvs-id edit-table-3.tcl,v 3.4.2.8 2000/09/22 01:39:03 kevin Exp
} {
    table_name
    adp:allhtml
    {table_id:naturalnum}
    {group_id:naturalnum,optional}
    admin_url

}

# -------------------------------------
# verify user and set up possible context bar
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id] || [empty_string_p $group_id]} {
    set group_id ""
    set return_url index
    set context_bar "[ad_context_bar [list /portals/ "Portals"] [list index "Administration"] [list edit-table?table_id=$table_id "Edit Table"] "Error"]"
} else {
    set context_bar ""
}
portal_check_administrator_maybe_redirect $user_id $group_id
#-------------------------------------

if {![info exists admin_url] || [empty_string_p $admin_url]} {
    set admin_url_sql_val [db_null]
} else {
    set admin_url_sql_val $admin_url
}

# --------------------------------------- 
# disallow table creation if table_name or adp is blank
if {[empty_string_p [string trim $table_name]] || [empty_string_p [string trim $adp]] } {
  
    # get generic display info
    portal_display_info

    doc_return  200 text/html "
    [portal_admin_header "Error"]
    $context_bar
    <hr>$font_tag
    Neither table name nor its HTML/ADP may be blank.
    [portal_admin_footer]"
    
    return
}
#----------------------------------------

# update table data
db_dml portals_admin_edit_table_update_data "
update portal_tables
set table_name = :table_name,
    adp = empty_clob(),
    creation_user = :user_id,
    modified_date = sysdate,
    admin_url = :admin_url_sql_val
where table_id = :table_id
returning adp into :1" -clobs [list $adp]

# flush memoization of pages with this table, done with foreach since the dbhandle must be released

set group_list [db_list_of_lists portal_admin_edit_table_list_page_map  "
select page_number, group_id
from portal_table_page_map map, portal_pages p
where table_id=$table_id 
and map.page_id=p.page_id
and group_id is not null"]

db_release_unused_handles

foreach pair $group_list {
    set page_number [lindex $pair 0]
    set new_group_id [lindex $pair 1]
    util_memoize_flush "portal_display_page $new_group_id $page_number group"
}

# redirect user 
if  {![empty_string_p $group_id]} {
    doc_return 200 text/html "<script>
    <!--
    self.window.close()
    //-->
    </script>"
} else {
    ad_returnredirect index
}






