# /www/admin/pull-down-menus/item-edit-2.tcl
ad_page_contract {

  Updates one menu item properties.

  @param menu_id which menu we're updating
  @param item_id which item of that menu we're updating
  @param label new menu label
  @param url url this menu label is pointing to

  @author aure@caltech.edu
  @creation-date 2000-02-18
  @cvs-id item-edit-2.tcl,v 1.4.2.5 2000/08/11 22:36:35 randyb Exp

} {
    menu_id:integer
    item_id:integer
    label:notnull
    {url ""}
}


db_dml menu_item_update "
update  pdm_menu_items
set     label = :label,
        url   = :url
where   item_id = :item_id" 

# figure out whether this menu is the default
set default_menu_p [db_string menu_is_default "select default_p from pdm_menus where menu_id = :menu_id"]

if {$default_menu_p == "t"} {
    # flush the current default menu from the memory cache - it will get memoized again when it's next called
    util_memoize_flush "ad_pdm_helper \"\" \"\" \"\" 1"
}

db_release_unused_handles
ad_returnredirect "items?menu_id=$menu_id"

