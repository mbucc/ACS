# $Id: toggle-active-p.tcl,v 3.0.4.1 2000/04/28 15:08:24 carsten Exp $
set_the_usual_form_variables

# topic

set db [ns_db gethandle]

ns_db dml $db "update bboard_topics set active_p = logical_negation(active_p) where topic='$QQtopic'"

ad_returnredirect "index.tcl"
