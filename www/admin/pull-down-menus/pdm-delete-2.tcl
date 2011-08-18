# /admin/pull-down-menus/pdm-delete-2.tcl
#
# Author: aure@arsdigita.com, Feb 2000
#
# $Id: pdm-delete-2.tcl,v 1.1.2.2 2000/04/28 15:09:19 carsten Exp $
# -----------------------------------------------------------------------------

ad_page_variables {menu_id}

set db [ns_db gethandle]

ns_db dml $db "begin transaction"
ns_db dml $db "delete from pdm_menu_items where menu_id = $menu_id"
ns_db dml $db "delete from pdm_menus where menu_id = $menu_id"
ns_db dml $db "end transaction"

ad_returnredirect ""

