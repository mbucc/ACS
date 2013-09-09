# /www/admin/pull-down-menus/item-delete.tcl
ad_page_contract {

  Delete menu item confirmation page.

  @param item_id Id of menu item we are about to delete.

  @author aure@arsdigita.com
  @creation-date Feb 2000
  @cvs-id item-delete.tcl,v 1.2.8.5 2000/09/22 01:35:54 kevin Exp

} {

    item_id:integer,notnull

}


db_0or1row one_item "
    select label, i.menu_id, menu_key
    from pdm_menu_items i, pdm_menus p 
    where i.item_id = :item_id
    and   p.menu_id = i.menu_id" 



doc_return  200 text/html "
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

