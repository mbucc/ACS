# /admin/pull-down-menus/item-edit-2.tcl
#
# by aure@caltech.edu
#
# 2000-02-18
#
# $Id: item-edit-2.tcl,v 1.1.2.2 2000/04/28 15:09:18 carsten Exp $

ad_page_variables {
    {item_id}
    {menu_id}
    {label}
    {url ""}
}

set db [ns_db gethandle]

ns_db dml $db "
update  pdm_menu_items
set     label = '[DoubleApos $label]',
        url   = '[DoubleApos $url]'
where   item_id = $item_id"

ad_returnredirect "items?menu_id=$menu_id"


