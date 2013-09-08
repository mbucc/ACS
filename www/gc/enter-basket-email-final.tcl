# enter-basket-email-final.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id enter-basket-email-final.tcl,v 3.0.12.3 2000/08/01 15:52:15 psu Exp
} {
    ad_id:integer
    email
}

set insert_sql {
    insert into user_picks (email, ad_id) 
    values (:email, :ad_id)"
}

db_dml gc_enter_basket_final_insert $insert_sql


ns_write "HTTP/1.0 302 Found
Location: basket-home.tcl
MIME-Version: 1.0
Set-Cookie:  HearstClassifiedBasketEmail=$email; path=/;
"

