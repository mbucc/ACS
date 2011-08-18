# $Id: delete.tcl,v 3.0 2000/02/06 03:26:14 ron Exp $
set_form_variables

# neighbor_to_neighbor_id

set db [neighbor_db_gethandle]

ns_db dml $db "delete from neighbor_to_neighbor where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"

ns_return 200 text/plain "Deleted posting $neighbor_to_neighbor_id"

