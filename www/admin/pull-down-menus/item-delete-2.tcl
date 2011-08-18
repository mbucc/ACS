# admin/pull-down-menus/item-delete-2.tcl
#
# Author: aure@arsdigita.com, Feb 2000
#
# $Id: item-delete-2.tcl,v 1.1.2.2 2000/04/28 15:09:18 carsten Exp $

ad_page_variables {
    {item_id}
    {menu_id}
}

set db [ns_db gethandle]

ns_db dml $db "delete from pdm_menu_items where item_id = $item_id"

ad_returnredirect "items?menu_id=$menu_id"