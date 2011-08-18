set_the_usual_form_variables

#reg_id, comments


set db [ns_db gethandle]

ns_db dml $db "update events_registrations set
comments='$QQcomments'
where reg_id = $reg_id"

ad_returnredirect "reg-view.tcl?reg_id=$reg_id"

