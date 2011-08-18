# $Id: picklist-item-swap.tcl,v 3.0.4.1 2000/04/28 15:08:40 carsten Exp $
set_the_usual_form_variables
# picklist_item_id, next_picklist_item_id, sort_key, next_sort_key

set db [ns_db gethandle]

# check that the sort keys are the same as before; otherwise the page
# they got here from is out of date

set item_match [database_to_tcl_string $db "select count(*) from ec_picklist_items where picklist_item_id=$picklist_item_id and sort_key=$sort_key"]

set next_item_match [database_to_tcl_string $db "select count(*) from ec_picklist_items where picklist_item_id=$next_picklist_item_id and sort_key=$next_sort_key"]

if { $item_match != 1 || $next_item_match != 1 } {
    ad_return_complaint 1 "<li>The page you came from appears to be out-of-date;
    perhaps someone has changed the picklist items since you last reloaded the page.
    Please go back to the previous page, push \"reload\" or \"refresh\" and try
    again."
    return
}

ns_db dml $db "begin transaction"
ns_db dml $db "update ec_picklist_items set sort_key=$next_sort_key where picklist_item_id=$picklist_item_id"
ns_db dml $db "update ec_picklist_items set sort_key=$sort_key where picklist_item_id=$next_picklist_item_id"
ns_db dml $db "end transaction"

ad_returnredirect "picklists.tcl"