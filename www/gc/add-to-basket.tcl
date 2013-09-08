# /www/gc/add-to-basket.tcl
ad_page_contract {
    Puts some classified ad into a user's basket.
    
    @author xxx
    @date unknown
    @cvs-id add-to-basket.tcl,v 3.1.6.3 2000/07/21 03:59:50 ron Exp
} {
    ad_id
}

set headers [ns_conn headers]
set cookie [ns_set get $headers Cookie]

if { $cookie == "" || 
     ( $cookie != "" && ![regexp {HearstClassifiedBasketEmail=([^;]*)$} $cookie match just_the_cookie] ) } {
    # there was no cookie header or there was, but it didn't match for us
    ad_returnredirect "enter-basket-email.tcl?ad_id=$ad_id"
    return
} 

# we get the last one if there are N
regexp {HearstClassifiedBasketEmail=([^;]*)$} $cookie match just_the_cookie
set key $just_the_cookie

db_dml insert_user_picks_dml "
  insert into user_picks (email, ad_id) 
  values (:key, :ad_id)" -bind [ad_tcl_vars_to_ns_set key ad_id]

db_release_unused_handles
ad_returnredirect "basket-home.tcl"

