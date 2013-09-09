# /www/admin/pull-down-menus/item-delete-2.tcl
ad_page_contract {

  Actually removes menu item.


  @param item_id menu item to be deleted from database
  @param menu_id id of menu undergoing surgery - needed for ad_returnredirect
  @author aure@arsdigita.com
  @creation-date Feb 2000
  @cvs-id item-delete-2.tcl,v 1.4.6.5 2000/08/11 22:37:18 randyb Exp

} {

    item_id:integer,notnull
    menu_id:integer,notnull

}


db_dml delete_menu_item "delete from pdm_menu_items where item_id = :item_id" 

# figure out whether this menu is the default
set default_menu_p [db_string menu_is_default "select default_p from pdm_menus where menu_id = :menu_id"]

if {$default_menu_p == "t"} {
    # flush the current default menu from the memory cache - it will get memoized again when it's next called
    util_memoize_flush "ad_pdm_helper \"\" \"\" \"\" 1"
}

db_release_unused_handles
ad_returnredirect "items?menu_id=$menu_id"
