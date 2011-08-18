# $Id: review-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:53 carsten Exp $
set_the_usual_form_variables
# product_id, product_name, publication, display_p, review, 
# review_id, author_name, review_date

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# see if this review is already there
if { [database_to_tcl_string $db "select count(*) from ec_product_reviews where review_id=$review_id"] > 0 } {
    ad_returnredirect "reviews.tcl?[export_url_vars product_id product_name]"
    return
}

ns_db dml $db "insert into ec_product_reviews
(review_id, product_id, publication, author_name, review, display_p, review_date, last_modified, last_modifying_user, modified_ip_address)
values
($review_id, $product_id, '$QQpublication', '$QQauthor_name', '$QQreview', '$QQdisplay_p', '$review_date',
sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')
"

ad_returnredirect "reviews.tcl?[export_url_vars product_id]"
