# set-spam-status.tcl
# 
# hqm@arsdigita.com
#
# force spam into a specific state

set_the_usual_form_variables

# spam_id,status

set db [ns_db gethandle] 
ns_db dml $db "update spam_history set status = '$status' where spam_id = $spam_id"

ad_returnredirect "old.tcl?spam_id=$spam_id"
