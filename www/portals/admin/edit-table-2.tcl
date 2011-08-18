# /portals/admin/edit-table-2.tcl
#
# Page that displays the edited portal table and prompts the user to confirm the changes
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: edit-table-2.tcl,v 3.0.4.1 2000/03/17 18:08:07 aure Exp $

#ad_page_variables {table_name adp table_id group_id admin_url}
set_the_usual_form_variables
# table_name, adp, table_id, group_id, admin_url

set db [ns_db gethandle]

# -----------------------------------------------
# verify user
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]||[empty_string_p $group_id]} {
    # user is a super administrator and arrived via index.tcl->edit-table.tcl
    set group_id ""
    set context_bar "[ad_context_bar [list /portals/ "Portals"] [list index.tcl "Administration"] [list edit-table.tcl?table_id=$table_id "Edit Table"] "Preview / Confirm"]"
    set super_p 1
} else {
    # we arrived from a given portal and are in pop-up
    set context_bar ""
    set super_p 0
}

portal_check_administrator_maybe_redirect $db $user_id $group_id
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
set shown_adp [portal_adp_parse $adp $db]

ns_return 200 text/html "
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
      <tr>$header_td [string toupper [portal_adp_parse $table_name $db]]</td></tr>
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

<form action=edit-table-3.tcl method=post>
[export_form_vars table_name adp group_id table_id admin_url]

<input type=submit value=\"Confirm Edit\">
$close_window_warning
</form>
</center>
[portal_admin_footer]"



