ad_page_contract {
    @cvs-id reject.tcl,v 3.3.2.3.2.5 2000/09/22 01:36:21 kevin Exp
} {
    user_id:integer,notnull
}


set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/view?user_state=[ns_urlencode need_admin_approv]"]
    return
}


db_1row user_full_name "select first_names || ' ' || last_name as name, user_state from users where user_id = :user_id"

append whole_page "[ad_admin_header "Rejecting $name"]

<h2>Rejecting $name</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] [list "view?user_state=[ns_urlencode need_admin_approv]" "Approval"] "Approve One"]

<hr>
"

db_dml set_user_state_rejected "update users 
set rejected_date = sysdate, user_state = 'rejected',
rejecting_user = :admin_user_id
where user_id = :user_id"

append whole_page " 
Done.

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
