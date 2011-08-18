# $Id: member-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:58 carsten Exp $
set_the_usual_form_variables
# user_class_id, user_class_name, user_id

set db [ns_db gethandle]

ns_db dml $db "delete from ec_user_class_user_map where user_id=$user_id and user_class_id=$user_class_id"

ad_audit_delete_row $db [list $user_class_id $user_id] [list user_class_id user_id] ec_user_class_user_map_audit

ad_returnredirect "members.tcl?[export_url_vars user_class_id user_class_name]"
