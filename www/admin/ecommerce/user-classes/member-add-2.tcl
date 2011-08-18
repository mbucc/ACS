# $Id: member-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:58 carsten Exp $
set_the_usual_form_variables
# user_class_id user_class_name user_id

# we need them to be logged in
set admin_user_id [ad_verify_and_get_user_id]

if {$admin_user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# see if they're already in ec_user_class_user_map, in which case just update
# their record

if { [database_to_tcl_string $db "select count(*) from ec_user_class_user_map where user_id=$user_id and user_class_id=$user_class_id"] > 0 } {
    ns_db dml $db "update ec_user_class_user_map
set user_class_approved_p='t', last_modified=sysdate, last_modifying_user=$admin_user_id, modified_ip_address='[DoubleApos [ns_conn peeraddr]]'
where user_id=$user_id and user_class_id=$user_class_id"
} else {
    ns_db dml $db "insert into ec_user_class_user_map
(user_id, user_class_id, user_class_approved_p, last_modified, last_modifying_user, modified_ip_address) 
values
($user_id, $user_class_id, 't', sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')
"
}

ad_returnredirect "one.tcl?[export_url_vars user_class_id user_class_name]"