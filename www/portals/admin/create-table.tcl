#
# /portals/admin/create-table.tcl
#
# first step in creation of a portal table prompting the user for name, html, and an optional administration URL
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: create-table.tcl,v 3.0.4.1 2000/03/17 18:08:07 aure Exp $
#

# ad_page_variables {group_id ""}
set_the_usual_form_variables 0 
# maybe group_id

set db [ns_db gethandle]

# ------------------------------------------
# verify user and set up the context bar and admin_url field
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    # the user came from index.tcl 
    set group_id ""
    set context_bar "[ad_context_bar [list /portals/ "Portals"] [list index.tcl "Administration"] "Create Table"]"
    set admin_url_table_row "<tr><td align=right valign=top>Administration URL (optional)</td>
    <td width=400><input type=text size=35 name=admin_url><br>
    You may associate an administration url with this table to which ordinary managers will be redirected.  
    I.e., they will not be able to edit the ADP.
    </td></tr>"
} else {
    # user is not acting as a super administrator
    set context_bar ""
    set admin_url_table_row ""
}
portal_check_administrator_maybe_redirect $db $user_id $group_id
# ------------------------------------------

# done with the database
ns_db releasehandle $db


# ---------------------------------
# serve the page

# Get generic display information
portal_display_info

set page_content "
[portal_admin_header "Create New Table"]
$context_bar

<hr>

<form method=POST action=create-table-2>
[export_form_vars group_id]

<table>
<tr>
   <td valign=top align=right>Table Name:</td>
   <td><textarea rows=2 cols=50 name=table_name></textarea></td>
</tr>
<tr>
  <td valign=top align=right>
  HTML/ADP:</td><td>
  <textarea rows=20 cols=70 name=adp></textarea></td>
</tr>
$admin_url_table_row
</table>

<center>
<p>
<input type=submit value=Preview>
</form>

</center>

<blockquote>

Your HTML/ADP will be embedded within an HTML table.  You don't have
to wrap whatever you type in a TABLE tag.  So, for example, a UL
followed by a bunch of LI tags would render just fine.  You can rely
on <code>\$db</code> being set (to a database connection from the main
pool).

</blockquote>

[portal_admin_footer]
"

ns_return 200 text/html $page_content



