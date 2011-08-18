# $Id: subcategory-edit.tcl,v 3.0.4.1 2000/04/28 15:08:35 carsten Exp $
set_the_usual_form_variables
# category_name, category_id, subcategory_id, subcategory_name

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars category_name category_id subcategory_id subcategory_name]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}


set db [ns_db gethandle]

ns_db dml $db "update ec_subcategories
set subcategory_name='$QQsubcategory_name',
last_modified=sysdate,
last_modifying_user=$user_id,
modified_ip_address='[DoubleApos [ns_conn peeraddr]]'
where subcategory_id=$subcategory_id"

ad_returnredirect "subcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]"
