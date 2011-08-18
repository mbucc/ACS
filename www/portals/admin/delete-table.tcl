#
# /portals/admin/delete-table.tcl
#
# Page that displays the portal table and prompts the user to confirm the delete
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: delete-table.tcl,v 3.0.4.1 2000/03/17 18:08:07 aure Exp $

# ad_page_variables {table_id}
set_the_usual_form_variables
# table_id

set db [ns_db gethandle]

# ---------------------------------
# verify the user
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    set group_id ""
}
portal_check_administrator_maybe_redirect $db $user_id $group_id
# ---------------------------------

# get table_name and adp of the proposed table to delete
set selection [ns_db 1row $db "select table_name, adp from portal_tables where table_id=$table_id"]
set_variables_after_query

# count the number of portal pages the table is currently displayed on
set pages_displayed_on [database_to_tcl_string $db "select count(*) from portal_table_page_map where table_id=$table_id"]

if { $pages_displayed_on > 0 } {
    set warning_text "This table is being displayed on $pages_displayed_on portal pages, are you sure you want to delete it from everywhere it appears?<p>"
} else {
    set warning_text "This table doesn't appear on any portal pages on this system, it looks safe to delete."
}


# -----------------------------------
# serve the page

# parse the adp
set shown_adp [portal_adp_parse $adp $db]

# Get generic display information
portal_display_info

set page_content "
[portal_admin_header "Confirm Delete"]
[ad_context_bar [list /portals/ "Portals"] [list index.tcl "Administration"] "Delete"]
<hr>
$warning_text
<table><tr><td>

$begin_table
<tr>
   $header_td [string toupper [portal_adp_parse $table_name $db]]</td>
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

ns_return 200 text/html $page_content
