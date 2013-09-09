# www/portals/admin/create-table-3.tcl

ad_page_contract {
    inserts into new table information and redirects back to originating page

    @author aure@arsdigita.com 
    @author dh@arsdigita.com
    @param table_name
    @param adp
    @param table_id
    @param group_id
    @param admin_url
    @creation-date 10/8/1999
    @cvs-id create-table-3.tcl,v 3.4.2.10 2001/01/11 23:09:20 khy Exp
} {
    table_name
    adp:allhtml
    table_id:naturalnum,notnull,verify
    group_id:naturalnum,optional
    admin_url
}


# -------------------------------------
# verify user and set up possible context bar
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id] || [empty_string_p $group_id]} {
    set group_id ""
    set return_url index
    set context_bar "[ad_context_bar [list /portals/ "Portals"] [list index "Administration"] [list create-table "Create Table"] "Error"]"
} else {
    set return_url "manage-portal?group_id=$group_id"
    set context_bar ""
}
portal_check_administrator_maybe_redirect $user_id $group_id
#-------------------------------------

if {![info exists admin_url] || [empty_string_p $admin_url] } {
    set admin_url_sql_value [db_null]
} else {
    set admin_url_sql_value $admin_url
}

# --------------------------------------- 
# disallow table creation if table_name or adp is blank
if {[empty_string_p [string trim $table_name]] || [empty_string_p [string trim $adp]] } {
  
    # get generic display info
    portal_display_info

    set page_content "
    [portal_admin_header "Error"]
    $context_bar
    <hr>$font_tag
    Neither table name nor its HTML/ADP may be blank.
    [portal_admin_footer]"
    doc_return  200 text/html $page_content 
    return
}

#----------------------------------------
# make sure this was not simply a double click
set check [db_string portal_create_table_table_check "select 1 from portal_tables where table_id = :table_id" -default ""]

if [empty_string_p $check] {
    
    # insert the table
    db_dml portal_create_table_portal_table_insert "
    insert into portal_tables 
    (table_id, table_name, adp, creation_user, modified_date, admin_url)
    values
    (:table_id, :table_name, empty_clob(), :user_id, sysdate, :admin_url_sql_value)
    returning adp into :1" -clobs [list $adp]
}

db_release_unused_handles

ad_returnredirect $return_url




