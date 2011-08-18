# $Id: toggle-index-p.tcl,v 3.0.4.1 2000/04/28 15:09:22 carsten Exp $
set_the_usual_form_variables

# page_id

set db [ns_db gethandle]

ns_db dml $db "update static_pages
set index_p = logical_negation(index_p),
    index_decision_made_by = 'human'
where page_id = $page_id"

ad_returnredirect "page-summary.tcl?[export_url_vars page_id]"
