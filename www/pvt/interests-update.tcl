# /www/pvt/interest-update.tcl
ad_page_contract {
    Update information about interests

    @author
    @creation-date
    @cvs-id interests-update.tcl,v 3.1.8.3 2000/07/21 04:03:43 ron Exp
} {
    {category_id:multiple ""}
}
set user_id [ad_verify_and_get_user_id]

set category_id_list $category_id

db_transaction {
    db_dml "interests_delete" "delete from users_interests where user_id = :user_id" -bind [ad_tcl_vars_to_ns_set user_id]
    foreach category_id $category_id_list {
        db_dml "interests_insert" "insert into users_interests
        (user_id, category_id, interest_date) 
        values
        (:user_id, :category_id, sysdate)" -bind [ad_tcl_vars_to_ns_set user_id category_id]
    }
}

ad_returnredirect "home.tcl"
