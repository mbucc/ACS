#  www/admin/ecommerce/user-classes/edit.tcl
ad_page_contract {
    @param user_class_name
    @param user_class_id

  @author
  @creation-date
  @cvs-id edit.tcl,v 3.1.6.4 2000/08/16 15:29:22 stevenp Exp
} {
    user_class_name
    user_class_id:naturalnum
}



db_dml update_ec_user_classes "update ec_user_classes
set user_class_name=:user_class_name
where user_class_id=:user_class_id"
db_release_unused_handles
ad_returnredirect "one.tcl?[export_url_vars user_class_id user_class_name]"