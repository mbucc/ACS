# picklist-item-delete-2.tcl

ad_page_contract {
    @param picklist_item_id
    @author
    @creation-date
    @cvs-id picklist-item-delete-2.tcl,v 3.1.6.4 2000/07/21 03:56:57 ron Exp
} {
    picklist_item_id
}






db_dml delete_item_from_picklist "delete from ec_picklist_items where picklist_item_id=:picklist_item_id"
db_release_unused_handles
ad_returnredirect "picklists.tcl"

