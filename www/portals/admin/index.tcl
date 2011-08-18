#
# /portals/admin/index.tcl
#
# Main index paage for the portals administration pages, which will redirect non-super-administrators
# to index-manager.tcl
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: index.tcl,v 3.2.2.1 2000/03/17 18:08:08 aure Exp $
#

set db [ns_db gethandle]

# Verify user
set user_id [ad_verify_and_get_user_id]
portal_check_administrator_maybe_redirect $db $user_id "" index-manager

# ---------------------------------------------------------------

# Get generic display information
portal_display_info

# Create a display of portals and their administrators 

set group_id_list [database_to_tcl_list $db "
    select group_id 
    from   user_groups 
    where  group_type = 'portal_group' 
    order by group_name"]

set portal_table ""

foreach group_id $group_id_list {

    # get the name of the portal group
    set group_name [database_to_tcl_string $db "
        select group_name from user_groups where group_id=$group_id"]

    # get a list of all authorized administrators
    set admin_list [database_to_tcl_list $db "
        select first_names||' '||last_name as name 
        from   users
        where  ad_group_member_p ( user_id, $group_id ) = 't'"]
    
    # special case for super administrators  - they have no portal page and a super administrator
    # may or may not be able to edit the list of super administrators
    if {$group_name != "Super Administrators"} {
	set link "<a href=manage-portal?[export_url_vars group_id]>$group_name</a>"
	set add_remove_link "<a href=add-manager?[export_url_vars group_id]>Add</a> / 
	<a href=delete-manager?[export_url_vars group_id]>Remove</a>"
    } else {
	set link $group_name
	if {[ad_parameter SuperAdminCanChangeSuperAdminP portals]} {
	    set add_remove_link "<a href=add-manager?[export_url_vars group_id]>Add</a> / 
	    <a href=delete-manager?[export_url_vars group_id]>Remove</a>"
	} else {
	    set add_remove_link "&nbsp;"
	}
    }

    append portal_table "
    <tr>
       $normal_td $link</td>
       $normal_td [join $admin_list ", "] &nbsp;</td> 
       $normal_td $add_remove_link </td>
    </tr>"
} 


# ------------------------------------------------------------

# show a list of all tables in the portals

set table_list [database_to_tcl_list_list $db "
    select   pt.table_name, pt.table_id, count(map.table_id)
    from     portal_tables pt, portal_table_page_map map
    where    pt.table_id = map.table_id(+)
    group by pt.table_name, pt.table_id
    order by pt.table_name"]

set counter 0
set table_table "" 

# using foreach since its possible that a table_name is an adp with db calls
foreach table_set $table_list {
    set table_name [lindex $table_set 0]
    set table_id [lindex $table_set 1]
    set count [lindex $table_set 2]

    append table_table "
        <tr>
        $normal_td [string toupper [portal_adp_parse $table_name $db]] ($count)</td>
        $normal_td<a href=edit-table?[export_url_vars table_id]>Edit</a> /
        <a href=delete-table?[export_url_vars table_id]>Delete</a> / 
        <a href=restore?[export_url_vars table_id]>Restore</a></td> 
        </tr>"
    incr counter
}

if { $counter == 0 } {
    set table_table "<tr><td colspan=2>There are no html tables in the database.</td></tr>" 
}

# ---------------------------------------------------------
# serve the page

set page_content  "
[portal_admin_header "[ad_parameter SystemName portals] Administration"]

[ad_context_bar [list /portals/ "Portals"] "Administration"]
$font_tag
<hr>
<table>
<tr>
<td>
Choose a group to manage or the edit the administration assignments. 
<p>
$begin_table
<tr>
$header_td GROUP</td>
$header_td ADMINISTRATORS </td>
$header_td </td>
</tr>
$portal_table 
$end_table
<p>
<a href=create-table>Create a new table</a> or select one of the following portal elements to edit, delete or restore a previous version:
<p>

$begin_table
<tr>
$header_td ACTIVE TABLES (# OF APPEARANCES)</td>
$header_td ACTIONS</td>
</tr>
$table_table
$end_table
<p>
<a href=view-deleted>View deleted tables</a> and optionally restore them.

</td>
</tr>
</table>

[portal_admin_footer]"

ns_return 200 text/html $page_content
















