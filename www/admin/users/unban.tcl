ad_page_contract {
    @cvs-id unban.tcl,v 3.0.12.3.2.3 2000/09/22 01:36:23 kevin Exp
} {
    user_id:integer,notnull
}


db_dml unused "update users set user_state = 'authorized' where user_id = :user_id"


set page_content "[ad_admin_header "Account resurrected"]

<h2>Account Resurrected</h2>

<hr>

[db_string admin_users_unban_confirmation "select first_names || ' ' || last_name from users where user_id = :user_id"] has been marked \"not deleted\".

[ad_admin_footer]
"



doc_return  200 text/html $page_content
