# www/portals/admin/edit-table.tcl

ad_page_contract {
    
    Page that displays the portal table and allows an administrator to edit the contents, either
    by allowing direct editing of the ADP or by redirecting the administrator to an associated
    administration page
    
    @author aure@arsdigita.com 
    @author dh@arsdigita.com
    @param table_id
    @param group_id
    @creation-date 10/8/1999
    @cvs-id edit-table.tcl,v 3.4.2.6 2000/09/22 01:39:04 kevin Exp

} {
    {table_id:naturalnum} 
    {group_id:naturalnum,optional}
}

# ---------------------------------
# verify user

set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id] || [empty_string_p $group_id]} {
    # the user came from index.tcl 
    set group_id ""
    set context_bar "[ad_context_bar [list /portals/ "Portals"] [list index "Administration"] "Edit Table" ]"
    set super_p 1
} else {
    # user arrived from a given portal and are in pop-up window
    set context_bar ""
    set super_p 0
}

portal_check_administrator_maybe_redirect $user_id $group_id

#----------------------------------

# Get generic display information
portal_display_info

# get the current version of the portal table (table_name, adp, admin_url)

set result ""
# dbtest_prepare_table

set query "select table_name, adp, admin_url from portal_tables where table_id = :table_id"

if {![db_0or1row portal_admin_edit_table_get_table_name $query ]} {
    ad_return_complaint 1 "Table id could not be found."
    db_release_unused_handles
    return
}


# ------------------------------------------------
# If this portal table has an associated admin_url, send the ordinary
# portal administrators to it.

if {![empty_string_p $admin_url] && $super_p==0 } {

    # redirect the non-superadmin to the admin_url
    ad_returnredirect $admin_url?[export_url_vars group_id]
    return

} elseif {![empty_string_p $admin_url] && $super_p==1} {

    # setup interface to allow Super Admin to edit the admin_url
    set admin_url_description "<ul>An ordinary administrator is not allowed to edit this portal table, instead he is redirected to the associated url to perform administration tasks.</ul> <P>"
    set admin_url_display_row "<tr><td>Associated URL:</td><td><a href=$admin_url>$admin_url</a></td></tr>"
    set admin_url_edit_row "<tr><td>Associated URL:</td><td><input type=textare name=\"admin_url\" value=\"[philg_quote_double_quotes $admin_url]\" size=35></td></tr>"

} elseif {[empty_string_p $admin_url] && $super_p==1 } {

    # setup interface to allow Super Admin to create the admin_url
    set admin_url_description "<ul>An ordinary administrator is currently allowed to edit this portal table.  If you want him to be redirected to an associated url instead, you may create one.</ul><p>" 
    set admin_url_display_row "<tr><td>Associated URL:</td><td>None</td></tr>"
    set admin_url_edit_row "<tr><td>Associated URL:</td><td><input type=textarea name=\"admin_url\" size=35></td></tr>"

} else {
    
    # the user isn't a super admin and there is no admin_url
    set admin_url_description ""
    set admin_url_display_row ""
    set admin_url_edit_row ""
}

# ---------------------------------------------------
# serve the page

# parse adp
if [catch { set shown_adp [portal_adp_parse $adp] } errmsg] {
    set shown_adp "Error evaluating ADP:  $errmsg"
}

set page_content "
[portal_admin_header "Edit [portal_adp_parse $table_name]"]
$context_bar
<hr>

$admin_url_description

<center>
<table><tr><td valign=top>Current Version:</td><td>
<table><tr><td>
$begin_table
<tr>
   $header_td [string toupper [portal_adp_parse $table_name]]</td>
</tr>
<tr>
   $normal_td$shown_adp</td>
</tr>
$end_table
</td></tr></table>
</td></tr>

$admin_url_display_row

</table><tr><td colspan=2><hr></td></tr><table>
<form method=POST action=edit-table-2>
[export_form_vars table_id group_id]

<tr>
   <td valign=top>Table Name:</td>
   <td><textarea rows=2 cols=50 wrap name=table_name>[ns_quotehtml $table_name]</textarea></td>
</tr>
<tr>
<td valign=top>
HTML/ADP:</td><td>
<textarea rows=20 cols=70 name=adp>[ns_quotehtml $adp]</textarea></td></tr>
$admin_url_edit_row
<tr><td colspan=2>
<center>
<p>
<input type=submit value=Preview></font>
</td>
</tr>

</table>
</center>

</form>
[portal_admin_footer]"


doc_return  200 text/html $page_content






