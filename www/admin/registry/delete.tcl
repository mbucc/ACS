# $Id: delete.tcl,v 3.0.4.1 2000/04/28 15:09:20 carsten Exp $
set_form_variables
# stolen_id, manufacturer

set db [ns_db gethandle]

ns_db dml $db "delete from stolen_registry where stolen_id = $stolen_id"

ad_returnredirect "search-one-manufacturer.tcl?manufacturer=[ns_urlencode $manufacturer]"
