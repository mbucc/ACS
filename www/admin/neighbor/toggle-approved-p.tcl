# $Id: toggle-approved-p.tcl,v 3.0.4.1 2000/04/28 15:09:11 carsten Exp $
set_form_variables

# neighbor_to_neighbor_id

set db [ns_db gethandle]

ns_db dml $db "update neighbor_to_neighbor set approved_p = logical_negation(approved_p) where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"

ad_returnredirect "view-one.tcl?[export_url_vars neighbor_to_neighbor_id]"




