# www/admin/portals/index.tcl

ad_page_contract {

    Main index page for the site owner administration of the portals system.
    A site owner can create new portals and change the super administrators of
    the system

    @author aure@arsdigita.com 
    @author dh@arsdigita.com
    @creation-date 10/8/1999
    @cvs-id index.tcl,v 3.4.2.6 2000/09/22 01:35:50 kevin Exp
    
} {
}    

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration 
# --------------------------------------
# make a list of the super administrators

set super_list ""
set super_count 0

db_foreach super_admins {
    select u.first_names||' '||u.last_name as name, 
           u.user_id
   from    users u, user_groups ug
   where   ug.group_name = 'Super Administrators' 
   and     ug.group_type = 'portal_group'
   and     ad_group_member_p ( u.user_id, ug.group_id ) = 't'
   order   by u.last_name
} {
    # name, user_id
    append super_list "<li>$name\n"
}

# --------------------------------------

# make  a list of all the portals

set portal_count 0
set portal_list ""

db_foreach portals {
    select group_name
    from   user_groups
    where  group_type = 'portal_group'
    and    group_name <> 'Super Administrators'
    order  by group_name
} {
    # group_name
    append portal_list "<li>$group_name</a>"
    incr portal_count
}

# ----------------------------------------
# get the group type for the Super Administrator group.

set group_type "portal_group"

# done with database
db_release_unused_handles

#----------------------------------------------------------
# serve the page
doc_return  200 text/html "[ad_admin_header "Portals Admin"]

<h2>Portals Admin</h2>

[ad_admin_context_bar "Portals Admin"]

<hr>

Documentation: <a href =\"/doc/portals.html\">/doc/portals.html</a>
<P>
<P>
The daily administration is done by the portal managers at <a href =\"/portals/admin/\">/portals/admin</a>.  Make sure you are in the Super Administrator list before visiting.
<P>
The portal-wide Super Administrators:
<ul>
$super_list
</ul>
<a href=add-manager>Add</a> or <a href=delete-manager>Remove</a> a Super Administrator.
<P>

The available portals:  
<ul>
$portal_list
</ul>
Portal administration assignments and creation of new portals is done at <a href=/admin/ug/group-type-new?[export_url_vars group_type]>/admin/ug/group-type-new.tcl</a>.
[ad_admin_footer]
"








