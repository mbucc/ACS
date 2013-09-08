# /www/admin/member-value/user-subscription-classify.tcl

ad_page_contract {
    
    Update the subscription class for the user. 
    @param user_id
    @param subscriber_class
    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 19:25:04 2000
    @cvs-id user-subscription-classify.tcl,v 3.2.2.4 2000/07/21 03:57:37 ron Exp

} {
    user_id:integer,notnull
    subscriber_class:notnull
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_return_error "no filter" "something wrong with the filter on add-charge; couldn't find registered user_id"
    return
}

if { [db_string mv_users_payment_count "select count(*) from users_payment where user_id = :user_id"] == 0 } {
    db_dml mv_users_payment_insertion "insert into users_payment (user_id, subscriber_class) values (:user_id, :subscriber_class)" 
} else {
    db_dml mv_update_users_payment "update users_payment set subscriber_class = :subscriber_class where user_id = :user_id"
}

db_release_unused_handles

ad_returnredirect "user-subscription?user_id=$user_id"
