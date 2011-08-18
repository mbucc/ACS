# /admin/pull-down-menus/pdm-delete.tcl
#
# Author: aure@arsdigita.com, Feb 2000
#
# $Id: pdm-delete.tcl,v 1.2.2.1 2000/03/16 05:33:09 aure Exp $
# -----------------------------------------------------------------------------

ad_page_variables {menu_id}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
    select   menu_key, default_p, count(item_id) as number_to_delete
    from     pdm_menu_items i, pdm_menus n 
    where    n.menu_id = $menu_id
    and      n.menu_id = i.menu_id(+)
    group by menu_key, default_p"]
set_variables_after_query

ns_db releasehandle $db

# Make sure they're not trying to delete the default!

if {$default_p == "t"} {
    ad_return_complaint 1 "<li>You cannot delete the default
    menu. Choose another menu as the default first."
    return
}


if {$menu_key == "admin"} {
    ad_return_complaint 1 "<li>You cannot delete the admin
    menu. Rename this menu if you want to delete it."
    return
}


ns_return 200 text/html "
[ad_header_with_extra_stuff "Delete Pull-Down Menu: $menu_key" [ad_pdm $menu_key 5 5] [ad_pdm_spacer $menu_key]]

<h2>Delete Pull-Down Menu: $menu_key</h2>

[ad_admin_context_bar [list "" "Pull-Down Menu"] [list "pdm-edit?menu_id=$menu_id" $menu_key] "Delete"]

<hr>

Do you really want to delete \"$menu_key\" and its $number_to_delete items?
<form method=post action=pdm-delete-2>
[export_form_vars menu_id]
<center>
<input type=submit value=Confirm>
</center>
</form>

[ad_admin_footer]"
