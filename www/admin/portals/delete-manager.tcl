# $Id: delete-manager.tcl,v 3.1 2000/03/01 08:45:00 yon Exp $
# delete-manager.tcl
#
# list of super administrators, clicking on one deletes him
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999



set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# get the group_id for Super Administrators
set group_id [database_to_tcl_string $db "select group_id 
    from user_groups
    where group_name = 'Super Administrators'
    and group_type = 'portal_group'"]

set group_name [portal_group_name $db $group_id]

set title "[ad_parameter SystemName portals]: Delete Administrator of [string toupper $group_name]"

# ---------------------------------------
set administrator_list [database_to_tcl_list_list $db "
    select  user_id, first_names, last_name
    from    users
    where   ad_group_member_p ( user_id, $group_id ) = 't'
    order by last_name"]

# done with the database
ns_db releasehandle $db


set admin_list "Choose Super Administrator to delete:<ul>"
set admin_count 0
foreach administrator $administrator_list {
    set name "[lindex $administrator 1] [lindex $administrator 2]"
    set person_id [lindex $administrator 0]
    set admin_id  $person_id
    append admin_list "\n<li><a href=delete-manager-2.tcl?[export_url_vars admin_id]>$name</a>"
    incr admin_count
}
append admin_list "</ul>"
if {$admin_count == 0} {
    set admin_list "There are currently no Super Administrators"
}

# --------------------------------------
# serve the page

ns_return 200 text/html "
[ad_admin_header "$title"]

<h2>$title</h2>

[ad_admin_context_bar [list index.tcl "Portals Admin"] "Remove Administrator"]

<hr>

<p>
$admin_list

[ad_admin_footer]"





