#  www/admin/ecommerce/user-classes/delete-2.tcl
ad_page_contract {
    @param user_class_id
    @author
  @creation-date
  @cvs-id delete-2.tcl,v 3.1.6.5 2000/08/18 21:47:00 stevenp Exp
} {
    user_class_id:naturalnum
}


# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}



# have to first remove references to this user_class in ec_user_class_user_map
# then it can be deleted from ec_user_classes

db_transaction {

set user_id_list [db_list get_user_id_list "select user_id from ec_user_class_user_map where user_class_id = :user_class_id"]

db_dml delete_unmap_users "delete from ec_user_class_user_map where user_class_id=:user_class_id
"

foreach user_id $user_id_list {
    ad_audit_delete_row [list $user_id $user_class_id] [list user_id user_class_id] ec_user_class_user_map_audit
}

db_dml delete_from_user_class "delete from ec_user_classes
where user_class_id=:user_class_id
"

ad_audit_delete_row [list $user_class_id] [list user_class_id] ec_user_classes_audit

}
db_release_unused_handles

ad_returnredirect "index.tcl"
