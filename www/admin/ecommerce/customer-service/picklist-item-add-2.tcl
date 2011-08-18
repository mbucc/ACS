# $Id: picklist-item-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:40 carsten Exp $
set_the_usual_form_variables
# picklist_item_id, picklist_item, picklist_name, prev_sort_key, next_sort_key

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# see first whether they already entered this category (in case they
# pushed submit twice), in which case, just redirect to 
# index.tcl

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select picklist_item_id from ec_picklist_items
where picklist_item_id=$picklist_item_id"]

if { $selection != ""} {
    ad_returnredirect "picklists.tcl"
    return
}

# now make sure that there is no picklist_item with the
# same picklist_name with a sort key equal to the new sort key

set n_conflicts [database_to_tcl_string $db "select count(*)
from ec_picklist_items
where picklist_name='$QQpicklist_name'
and sort_key = ($prev_sort_key + $next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The picklist management page you came from appears
    to be out-of-date; perhaps someone has changed the picklist items since you
    last reloaded the page.
    Please go back to <a href=\"picklists.tcl\">the picklist management page</a>,
    push \"reload\" or \"refresh\" and try again."
    return
}

ns_db dml $db "insert into ec_picklist_items
(picklist_item_id, picklist_item, picklist_name, sort_key, last_modified, last_modifying_user, modified_ip_address)
values
($picklist_item_id, '$QQpicklist_item', '$QQpicklist_name', ($prev_sort_key + $next_sort_key)/2, sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"

ad_returnredirect "picklists.tcl"
