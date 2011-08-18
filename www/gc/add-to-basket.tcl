# $Id: add-to-basket.tcl,v 3.0.4.1 2000/04/28 15:10:30 carsten Exp $
set_form_variables

# ad_id is the only interesting one

set db [gc_db_gethandle]

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

set insert_sql "insert into user_picks (email, ad_id) 
                values ('[DoubleApos $key]',$ad_id)"

ns_db dml $db $insert_sql

ad_returnredirect "basket-home.tcl"
