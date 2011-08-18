# $Id: delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:58 carsten Exp $
set_the_usual_form_variables
# user_class_id

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# have to first remove references to this user_class in ec_user_class_user_map
# then it can be deleted from ec_user_classes

ns_db dml $db "begin transaction"

set user_id_list [database_to_tcl_list $db "select user_id from ec_user_class_user_map where user_class_id = $user_class_id"]

ns_db dml $db "delete from ec_user_class_user_map where user_class_id=$user_class_id
"

foreach user_id $user_id_list {
    ad_audit_delete_row $db [list $user_id $user_class_id] [list user_id user_class_id] ec_user_class_user_map_audit
}

ns_db dml $db "delete from ec_user_classes
where user_class_id=$user_class_id
"

ad_audit_delete_row $db [list $user_class_id] [list user_class_id] ec_user_classes_audit

ns_db dml $db "end transaction"

ad_returnredirect "index.tcl"
