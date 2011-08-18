# $Id: update-manufacturer.tcl,v 3.0.4.1 2000/04/28 15:09:20 carsten Exp $
set_the_usual_form_variables
# stolen_id, manufacturer

set db [ns_db gethandle]

ns_db dml $db "update stolen_registry set manufacturer = '$manufacturer' where stolen_id = $stolen_id"

ad_returnredirect "one-case.tcl?stolen_id=$stolen_id"