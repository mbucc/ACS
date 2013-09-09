#  www/admin/ecommerce/user-classes/add-2.tcl
ad_page_contract {
    @param user_class_id
    @param user_class_name

  @author
  @creation-date
  @cvs-id add-2.tcl,v 3.1.6.6 2001/01/12 19:35:02 khy Exp
} {
    user_class_id:naturalnum,notnull,verify
    user_class_name
}



# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# see if it's already in the database, meaning the user pushed reload



if { [db_string get_uc_count "select count(*) from ec_user_classes where user_class_id=:user_class_id"] > 0 } {
    ad_returnredirect index.tcl
    return
}

db_dml insert_new_uc "insert into ec_user_classes
(user_class_id, user_class_name, last_modified, last_modifying_user, modified_ip_address)
values
(:user_class_id,:user_class_name, sysdate, :user_id, '[DoubleApos [ns_conn peeraddr]]')
"
db_release_unused_handles
ad_returnredirect index.tcl
