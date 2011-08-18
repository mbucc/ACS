# $Id: user-identification-edit.tcl,v 3.0.4.1 2000/04/28 15:08:41 carsten Exp $
set_the_usual_form_variables
# user_identification_id, first_names, last_name, email, postal_code, other_id_info

set db [ns_db gethandle]
ns_db dml $db "update ec_user_identification
set first_names='$QQfirst_names',
last_name='$QQlast_name',
email='$QQemail',
postal_code='$QQpostal_code',
other_id_info='$QQother_id_info'
where user_identification_id=$user_identification_id"

ad_returnredirect "user-identification.tcl?[export_url_vars user_identification_id]"

