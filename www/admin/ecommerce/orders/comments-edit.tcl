# $Id: comments-edit.tcl,v 3.0.4.1 2000/04/28 15:08:43 carsten Exp $
set_the_usual_form_variables
# order_id, cs_comments

set db [ns_db gethandle]

ns_db dml $db "update ec_orders set cs_comments='$QQcs_comments' where order_id=$order_id"

ad_returnredirect "one.tcl?[export_url_vars order_id]"