# $Id: picklist-item-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:40 carsten Exp $
set_the_usual_form_variables
# picklist_item_id

set db [ns_db gethandle]

ns_db dml $db "delete from ec_picklist_items where picklist_item_id=$picklist_item_id"

ad_returnredirect "picklists.tcl"