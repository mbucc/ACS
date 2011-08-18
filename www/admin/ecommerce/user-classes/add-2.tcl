# $Id: add-2.tcl,v 3.0.4.1 2000/04/28 15:08:57 carsten Exp $
set_the_usual_form_variables
# user_class_id, user_class_name

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# see if it's already in the database, meaning the user pushed reload

set db [ns_db gethandle]

if { [database_to_tcl_string $db "select count(*) from ec_user_classes where user_class_id=$user_class_id"] > 0 } {
    ad_returnredirect index.tcl
    return
}

ns_db dml $db "insert into ec_user_classes
(user_class_id, user_class_name, last_modified, last_modifying_user, modified_ip_address)
values
($user_class_id,'$QQuser_class_name', sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]')
"

ad_returnredirect index.tcl
