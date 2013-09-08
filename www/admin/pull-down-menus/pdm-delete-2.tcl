# /www/admin/pull-down-menus/pdm-delete-2.tcl
ad_page_contract {

  Deletes menu and all its items from the database.

  @param menu_id Menu to be deleted with all associated items.

  @author aure@arsdigita.com
  @creation-date Feb 2000
  @cvs-id pdm-delete-2.tcl,v 1.3.6.6 2000/09/08 00:12:25 bquinn Exp

} {

  menu_id:integer,notnull

}

db_transaction {
  db_dml delete_menu_items "delete from pdm_menu_items where menu_id = :menu_id"
  db_dml delete_menu "delete from pdm_menus where menu_id = :menu_id" 
}


# figure out whether this menu is the default
set default_menu_p [db_string menu_is_default {
    select default_p from pdm_menus where menu_id = :menu_id
} -default "0"]

if {$default_menu_p == "t"} {
    # flush the current default menu from the memory cache - it will get memoized again when it's next called
    util_memoize_flush "ad_pdm_helper \"\" \"\" \"\" 1"
}

db_release_unused_handles
ad_returnredirect ""

