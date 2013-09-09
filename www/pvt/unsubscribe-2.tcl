# unsubscribe-2.tcl

ad_page_contract {
    @cvs-id unsubscribe-2.tcl,v 3.0.14.5 2000/09/22 01:39:12 kevin Exp
} 


set user_id [ad_get_user_id]

db_dml pvt_user_unsubscribe {
    update users set user_state='deleted' where user_id = :user_id
}

doc_return  200 text/html "[ad_header "Account deleted"]

<h2>Account Deleted</h2>

<hr>

Your account at [ad_system_name] has been marked \"deleted\".

[ad_footer]
"
