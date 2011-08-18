# $Id: toggle-active-p.tcl,v 3.1.2.1 2000/04/28 15:09:03 carsten Exp $
set_the_usual_form_variables

# domain_id

set db [ns_db gethandle]

ns_db dml $db "update ad_domains set active_p = logical_negation(active_p) where domain_id = $domain_id"

ad_returnredirect "index.tcl"
