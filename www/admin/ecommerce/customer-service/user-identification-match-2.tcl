# user-identification-match-2.tcl

ad_page_contract {
    @param user_identification_id
    @param d_user_id

    @author
    @creation-date
    @cvs-id user-identification-match-2.tcl,v 3.1.6.3 2000/07/21 03:56:59 ron Exp
} {
    user_identification_id
    d_user_id
}




db_dml update_user_id_set_new_uid "update ec_user_identification set user_id=:d_user_id where user_identification_id=:user_identification_id"
db_release_unused_handles

ad_returnredirect "/admin/users/one.tcl?user_id=$d_user_id"