# www/portals/admin/delete-manager.tcl

ad_page_contract {
    allows the user to delete managers from this portal group.
    shows the user a list of managers. they pick the one they want to 
    delete.

    @author Aure aure@arsdigita.com 
    @author Dave Hill dh@arsdigita.com
    @param group_id
    @cvs-id delete-manager.tcl,v 3.4.2.6 2000/09/22 01:39:03 kevin Exp
} {
    {group_id:naturalnum,notnull}
}

# -------------------------------------------
# verify user
set user_id [ad_verify_and_get_user_id]

if {![info exists group_id]} {
    ad_returnredirect index
    return
}
set group_name [portal_group_name $group_id]
portal_check_administrator_maybe_redirect $user_id
# ------------------------------------------


set administrator_list [db_list_of_lists portals_delete_manager_list_name "
    select  user_id, first_names, last_name
    from    users
    where   ad_group_member_p ( user_id, :group_id ) = 't'
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



doc_return  200 text/html $page_content






