#
# /portals/admin/restore-2.tcl
#
# shows the user the proposed table to restore and prompts the user to confirm the action
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: restore-2.tcl,v 3.0.4.1 2000/03/17 18:08:11 aure Exp $
#

#ad_page_variables {audit_id}
set_the_usual_form_variables
# audit_id


# ------------------------------
# verify user
set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    set group_id ""
}
portal_check_administrator_maybe_redirect $db $user_id $group_id
# -----------------------------

# get the portal table
set selection [ns_db 1row $db "
    select table_id, table_name, adp, admin_url
    from   portal_tables_audit
    where  audit_id = $audit_id"]

set_variables_after_query

if {![empty_string_p $admin_url]} {
    set admin_url_description "An ordinary administrator is not allowed to edit this portal table, instead he is redirected to the associated url <a href=$admin_url?[export_url_vars group_id]>$admin_url</a> to perform administration tasks.<P>"
} else {
    set admin_url_description "An ordinary administrator is currently allowed to edit this portal table.  There is no associated url." 
}

# -----------------------------
# serve the page

# parse the adp
set shown_adp [portal_adp_parse $adp $db]

# Get generic display information
portal_display_info

set page_content "
[portal_admin_header "Review / Confirm"]

[ad_context_bar [list /portals/ "Portals"] [list index.tcl "Administration" ] [list restore.tcl?table_id=$table_id "Versions"] "Review"]
<hr>

$admin_url_description

You may choose 'restore' to replace the current table with this version.
<table><tr><td>

$begin_table
<tr>
   $header_td [string toupper [portal_adp_parse $table_name $db]]</td>
</tr>
<tr>
   $normal_td$shown_adp</td>
</tr>
$end_table

<form action=restore-3 method=post>
[export_form_vars audit_id]
<center>
<input type=submit value=\"Restore\">

</td></tr></table>

[portal_admin_footer]
"

ns_return 200 text/html $page_content
