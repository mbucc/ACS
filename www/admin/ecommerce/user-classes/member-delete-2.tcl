#  www/admin/ecommerce/user-classes/member-delete-2.tcl
ad_page_contract {
    @param user_class_id
    @param user_class_name
    @param user_id
  @author
  @creation-date
  @cvs-id member-delete-2.tcl,v 3.1.6.4 2000/08/16 15:29:23 stevenp Exp
} {
    user_class_id:naturalnum
    user_class_name
    user_id:naturalnum
}





db_dml delete_user_from_eccmap "delete from ec_user_class_user_map where user_id=:user_id and user_class_id=:user_class_id"

ad_audit_delete_row [list $user_class_id $user_id] [list user_class_id user_id] ec_user_class_user_map_audit
db_release_unused_handles

ad_returnredirect "members.tcl?[export_url_vars user_class_id user_class_name]"
