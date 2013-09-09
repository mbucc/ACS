# www/portals/admin/delete-table.tcl

ad_page_contract {
    Page that displays the portal table and prompts the user to confirm the delete

    @author aure@arsdigita.com
    @author dh@arsdigita.com
    @param table_id
    @creation-date 10/8/1999
    @cvs-id delete-table.tcl,v 3.3.2.5 2000/09/22 01:39:03 kevin Exp
} {
    {table_id:naturalnum}
}

# ---------------------------------
# verify the user
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    set group_id ""
}
portal_check_administrator_maybe_redirect $user_id $group_id
# ---------------------------------

# get table_name and adp of the proposed table to delete
if {![db_0or1row portal_admin_delete_table_get_table_name "select table_name, adp from portal_tables where table_id=:table_id"]} {
    ad_return_complaint 1 "Table id not found."
}

# count the number of portal pages the table is currently displayed on
set pages_displayed_on [db_string portal_admin_delete_table_get_count "select count(*) from portal_table_page_map where table_id=:table_id"]

if { $pages_displayed_on > 0 } {
    set warning_text "This table is being displayed on $pages_displayed_on portal pages, are you sure you want to delete it from everywhere it appears?<p>"
} else {
    set warning_text "This table doesn't appear on any portal pages on this system, it looks safe to delete."
}

# -----------------------------------
# serve the page

# parse the adp
set shown_adp [portal_adp_parse $adp]

# Get generic display information
portal_display_info

set page_content "
[portal_admin_header "Confirm Delete"]
[ad_context_bar [list /portals/ "Portals"] [list index "Administration"] "Delete"]
<hr>
$warning_text
<table><tr><td>

$begin_table
<tr>
   $header_td [string toupper [portal_adp_parse $table_name]]</td>
</tr>
<tr>
   $normal_td$adp</td>
</tr>
$end_table

<form action=delete-table-2 method=post>
[export_form_vars table_id]
<center>
<input type=submit value=\"Confirm Delete\">

</td></tr></table>

[portal_admin_footer]"


doc_return  200 text/html $page_content
