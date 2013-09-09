# www/portals/admin/edit-table-2.tcl

ad_page_contract {

    Page that displays the edited portal table and prompts the user to confirm the changes

    @author aure@arsdigita.com 
    @author dh@arsdigita.com
    @creation-date 10/8/1999
    @param table_name
    @param adp
    @param table_id
    @param group_id
    @param admin_url
    @cvs-id edit-table-2.tcl,v 3.4.2.7 2000/09/22 01:39:03 kevin Exp
} {
    table_name
    adp:allhtml
    {table_id:naturalnum}
    {group_id:naturalnum,optional}
    admin_url
}


# -----------------------------------------------
# verify user
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]||[empty_string_p $group_id]} {
    # user is a super administrator and arrived via index.tcl->edit-table.tcl
    set group_id ""
    set context_bar "[ad_context_bar [list /portals/ "Portals"] [list index "Administration"] [list edit-table?table_id=$table_id "Edit Table"] "Preview / Confirm"]"
    set super_p 1
} else {
    # we arrived from a given portal and are in pop-up
    set context_bar ""
    set super_p 0
}

portal_check_administrator_maybe_redirect $user_id $group_id
#-------------------------------------------------

# show window-will-close warning if the page is in a pop-up window
if  {$super_p == 0} {
    set close_window_warning "<br>(this will close this window)"
} else {
    set close_window_warning ""
}

# admin_url display
if {![info exists admin_url] || [empty_string_p $admin_url]} {
    set admin_url ""
    set admin_url_display "<tr><td>Associated URL:</td><td>None</td></tr>"
} else {
    set admin_url [string trim $admin_url]
    set admin_url_display "<tr><td>Associated URL:</td><td><a href=\"$admin_url\">$admin_url</a></td></tr>"
}

# ------------------------------------------
# serve the page
   
# Get generic display information
portal_display_info

# parse adp
set shown_adp [portal_adp_parse $adp]

set page_content "
[portal_admin_header "Preview / Confirm"]
$context_bar
<hr>
<center>

<table>
<tr>
<td valign=top>New Version:</td>
<td>
 <table>
  <tr><td>$begin_table
      <tr>$header_td [string toupper [portal_adp_parse $table_name]]</td></tr>
      <tr>$normal_td$shown_adp</td></tr>
      $end_table
  </td></tr>
 </table>
</td>
</tr>
</table>
<table>

$admin_url_display

</table>

<form action=edit-table-3 method=post>
[export_form_vars table_name adp group_id table_id admin_url]

<input type=submit value=\"Confirm Edit\">
$close_window_warning
</form>
</center>
[portal_admin_footer]"


doc_return  200 text/html $page_content

