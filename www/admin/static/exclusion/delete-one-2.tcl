# $Id: delete-one-2.tcl,v 3.0.4.1 2000/04/28 15:09:23 carsten Exp $
set_form_variables
# exclusion_pattern_id

set db [ns_db gethandle]

ns_db dml $db "delete from static_page_index_exclusion
where exclusion_pattern_id = $exclusion_pattern_id"

ad_returnredirect "../index.tcl"
