# www/portals/admin/restore-2.tcl

ad_page_contract {
    shows the user the proposed table to restore and prompts the user to confirm the 
    action
    
    @author Aure aure@arsdigita.com 
    @author Dave Hill dh@arsdigita.com
    @param audit_id: the id of the table to be restored, in the audit table.
    @cvs-id restore-2.tcl,v 3.3.2.6 2000/09/22 01:39:04 kevin Exp
} {
    {audit_id:naturalnum,notnull}
}

# ------------------------------
# verify user

set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    set group_id ""
}
portal_check_administrator_maybe_redirect $user_id $group_id
# -----------------------------

# get the portal table

db_0or1row portals_admin_restore_2_select_info_from_portal_tables_audit "select table_id, table_name, adp, admin_url
    from   portal_tables_audit
    where  audit_id = :audit_id" 

if {![empty_string_p $admin_url]} {
    set admin_url_description "An ordinary administrator is not allowed to edit this portal table, instead he is redirected to the associated url <a href=$admin_url?[export_url_vars group_id]>$admin_url</a> to perform administration tasks.<P>"
} else {
    set admin_url_description "An ordinary administrator is currently allowed to edit this portal table.  There is no associated url." 
}

# -----------------------------
# serve the page

# parse the adp
set shown_adp [portal_adp_parse $adp]

# Get generic display information
portal_display_info

set page_content "
[portal_admin_header "Review / Confirm"]

[ad_context_bar [list /portals/ "Portals"] [list index "Administration" ] [list restore?table_id=$table_id "Versions"] "Review"]
<hr>

$admin_url_description

You may choose 'restore' to replace the current table with this version.
<table><tr><td>

$begin_table
<tr>
   $header_td [string toupper [portal_adp_parse $table_name]]</td>
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



doc_return  200 text/html $page_content
