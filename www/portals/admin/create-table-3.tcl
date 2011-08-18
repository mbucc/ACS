#
# /portals/admin/create-table-3.tcl
#
# inserts into new table information and redirects back to originating page
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999# edit-table-3.tcl
#
# $Id: create-table-3.tcl,v 3.0.4.2 2000/04/28 15:11:17 carsten Exp $

set_the_usual_form_variables
# ad_page_varialbes {table_name adp table_id admin_url}
# table_name, adp, table_id, admin_url

set db [ns_db gethandle]

# -------------------------------------
# verify user and set up possible context bar
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id] || [empty_string_p $group_id]} {
    set group_id ""
    set return_url index
    set context_bar "[ad_context_bar [list /portals/ "Portals"] [list index.tcl "Administration"] [list create-table.tcl "Create Table"] "Error"]"
} else {
    set return_url "manage-portal?group_id=$group_id"
    set context_bar ""
}
portal_check_administrator_maybe_redirect $db $user_id $group_id
#-------------------------------------

if {![info exists admin_url] || [empty_string_p $admin_url] } {
    set admin_url_sql_value "NULL"
} else {
    set admin_url_sql_value  "'$QQadmin_url'"
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
    ns_return 200 text/html $page_content 
    return
}


#----------------------------------------
# make sure this was not simply a double click
set check [database_to_tcl_string_or_null $db "select 1 from portal_tables where table_id = $table_id"]

if [empty_string_p $check] {
    
    # insert the table
    ns_ora clob_dml $db "
    insert into portal_tables 
    (table_id, table_name, adp, creation_user, modified_date, admin_url)
    values
    ($table_id, '$QQtable_name', empty_clob(), $user_id, sysdate, $admin_url_sql_value)
    returning adp into :one" $adp
}

ns_db releasehandle $db

ad_returnredirect $return_url


