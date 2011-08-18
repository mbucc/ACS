#
# /portals/admin/delete-manager.tcl
#
# list of managers that may be delete from the list of portal managers for the group
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: delete-manager.tcl,v 3.1.2.2 2000/04/28 15:11:17 carsten Exp $
#

ad_page_variables {group_id}

set db [ns_db gethandle]

# -------------------------------------------
# verify user
set user_id [ad_verify_and_get_user_id]

if {![info exists group_id]} {
    ad_returnredirect index
    return
}
set group_name [portal_group_name $db $group_id]
portal_check_administrator_maybe_redirect $db $user_id
# ------------------------------------------

set administrator_list [database_to_tcl_list_list $db "
    select  user_id, first_names, last_name
    from    users
    where   ad_group_member_p ( user_id, $group_id ) = 't'
    order by last_name"]

set admin_list "Choose Manager to delete:<ul>"
set admin_count 0
foreach administrator $administrator_list {
    set name "[lindex $administrator 1] [lindex $administrator 2]"
    set person_id [lindex $administrator 0]
    set admin_id  $person_id
    append admin_list "\n<li><a href=delete-manager-2?[export_url_vars group_id admin_id]>$name</a>"
    incr admin_count
}

if { $admin_count == 0 } { 
    set admin_list "There are currently no administrators of this portal group."
}

# ------------------------------------
# serve the page

set page_content "
[portal_admin_header "Delete Administrator of [string toupper $group_name]"]

[ad_context_bar [list /portals/ "Portals"] [list index "Administration"] "Delete Manager"]
<hr>

$admin_list
</ul>
[portal_admin_footer]"

ns_return 200 text/html $page_content



