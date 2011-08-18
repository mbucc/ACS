# $Id: active-toggle.tcl,v 3.0.4.1 2000/04/28 15:08:37 carsten Exp $
set_the_usual_form_variables
# table_name, primary_key_name, primary_key_value, active_p

set db [ns_db gethandle]
ns_db dml $db "update $table_name
set active_p='$active_p'
where $primary_key_name='$QQ$primary_key_value'"

ad_returnredirect picklists.tcl
