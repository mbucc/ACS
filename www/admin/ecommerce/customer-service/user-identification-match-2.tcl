# $Id: user-identification-match-2.tcl,v 3.0.4.1 2000/04/28 15:08:41 carsten Exp $
set_the_usual_form_variables
# user_identification_id, d_user_id

set db [ns_db gethandle]
ns_db dml $db "update ec_user_identification set user_id=$d_user_id where user_identification_id=$user_identification_id"

ad_returnredirect "/admin/users/one.tcl?user_id=$d_user_id"