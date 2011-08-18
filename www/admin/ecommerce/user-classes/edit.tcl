# $Id: edit.tcl,v 3.0.4.1 2000/04/28 15:08:58 carsten Exp $
set_the_usual_form_variables
# user_class_name, user_class_id

set db [ns_db gethandle]
ns_db dml $db "update ec_user_classes
set user_class_name='$QQuser_class_name'
where user_class_id=$user_class_id"

ad_returnredirect "one.tcl?[export_url_vars user_class_id user_class_name]"