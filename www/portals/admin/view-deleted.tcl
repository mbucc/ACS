# /portals/admin/view-deleted.tcl

ad_page_contract {
    Page that displays the names of deleted tables

    @author aure@arsdigita.com and dh@arsdigita.com
    @creation-date 10/8/1999
    @cvs-id view-deleted.tcl,v 3.2.2.7 2000/09/22 01:39:05 kevin Exp
} {

}

# verify the user
set user_id [ad_verify_and_get_user_id]
portal_check_administrator_maybe_redirect $user_id "" index-manager

# Get generic display information
portal_display_info

# -------------------------------------------------
# show a list of all deleted tables in the portals
set sql_query "
    select   distinct table_id, table_name
    from     portal_tables_audit
    where    table_id not in (select table_id from portal_tables)
    order by table_name"
 

set table_list [db_list_of_lists portals_admin_view_delete_list_delete_tables $sql_query]

set counter 0
set table_table "" 

foreach table_pair $table_list {
    set table_id [lindex $table_pair 0]
    set table_name [lindex $table_pair 1]

    append table_table "
        <tr>
        $normal_td[string toupper [portal_adp_parse $table_name]] &nbsp;</td>
        <td><a href=restore?[export_url_vars table_id]>View versions</a>
        </tr>"
    incr counter
}
        
if { $counter == 0 } {
    set table_table "<tr><td colspan=2>There are no deleted tables in the database.</td></tr>" 
}

# -------------------------------------------------
# serve the page

set page_content "
[portal_admin_header "Deleted Tables"]
[ad_context_bar [list /portals/ "Portals"] "Administration"]
$font_tag
<hr>
<table><tr><td>
$begin_table
<tr>
$header_td ACTIVE TABLES (# OF APPEARANCES)</td>
$header_td ACTIONS</td>
</tr>
$table_table
$end_table
<p>

</td></tr></table>

[portal_admin_footer]"


doc_return  200 text/html $page_content










