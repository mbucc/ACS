# admin/pdm/item-delete.tcl
#
# Author: aure@arsdigita.com, Feb 2000
#
# $Id: item-delete.tcl,v 1.1.2.1 2000/03/16 05:33:08 aure Exp $

ad_page_variables {
    {item_id}
}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
    select label, i.menu_id, menu_key
    from pdm_menu_items i, pdm_menus p 
    where i.item_id = $item_id
    and   p.menu_id = i.menu_id"]

set_variables_after_query

ns_db releasehandle $db

ns_return 200 text/html "
[ad_header_with_extra_stuff "Delete Menu Item: $menu_key"]
[ad_pdm $menu_key 5 5]
<h2>Delete Menu Item: $label</h2>
[ad_admin_context_bar [list "" "Pull-Down Menus"] [list "pdm-edit?menu_id=$menu_id" $menu_key] [list "item-edit?item_id=$item_id" $label] "Delete"]
<hr>

Do you really want to delete \"$label\" from menu: \"$menu_key\"?

<form action=item-delete-2>
[export_form_vars menu_id item_id]
<center>
<input type=submit value=Confirm>
</center>
</form>
[ad_admin_footer]"

