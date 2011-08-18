#
# /portals/admin/create-table-2.tcl
#
# Page that displays the new portal table and prompts the user to confirm
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: create-table-2.tcl,v 3.0.4.1 2000/03/17 18:08:06 aure Exp $

# ad_page_variables {table_name adp group_id admin_url}
set_the_usual_form_variables 0
# table_name, adp, maybe group_id, admin_url

set db [ns_db gethandle]

# verify user ---------------------------------
set user_id [ad_verify_and_get_user_id]
if  {![info exists group_id]||[empty_string_p $group_id]} { 
    # user is a super administrator and arrived via index.tcl->create-table.tcl    
    set group_id ""
    set context_bar "[ad_context_bar [list /portals/ "Portals"] [list index.tcl "Administration"] [list create-table.tcl "Create Table"] "Preview / Confirm"]"
} else {
    # user is not acting as a super administrator
    set context_bar ""
}
portal_check_administrator_maybe_redirect $db $user_id $group_id
#---------------------------------------------

# get next table_id (on this page for double-click protection)
set table_id [database_to_tcl_string $db "select portal_table_id_sequence.nextval from dual"]

# set up contextbar and admin_url display if user is a super administrator
if {![info exists admin_url]} {
    set admin_url ""
} else {
    set admin_url [string trim $admin_url]
}


if { ![empty_string_p $admin_url] } {
    set admin_url_display "Administration URL: <a href=\"$admin_url\">$admin_url</a><p>"
} else {
    set admin_url_display ""
}

# --------------------------------------
# serve the page

# parse the adp
set shown_adp [portal_adp_parse $adp $db]

# Get generic display information
portal_display_info

set page_content "
[portal_admin_header "Preview / Confirm"]
$context_bar
<hr>$font_tag
<center>
<table><tr><td>

$begin_table
<tr>
   $header_td [string toupper [portal_adp_parse $table_name $db]]</td>
</tr>
<tr>
   $normal_td$shown_adp</td>
</tr>
$end_table
</td></tr></table>

<form action=create-table-3.tcl method=post>
[export_form_vars table_name adp group_id table_id admin_url]

$admin_url_display<p>

<input type=submit value=Create>
</center>
[portal_admin_footer]"

ns_return 200 text/html $page_content
