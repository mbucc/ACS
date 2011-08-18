# $Id: review-submit-3.tcl,v 3.0.4.1 2000/04/28 15:10:02 carsten Exp $
set_the_usual_form_variables
# product_id, rating, one_line_summary, user_comment, comment_id
# possibly usca_p

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {

    set return_url "[ns_conn url]?[export_url_vars product_id prev_page_url prev_args_list altered_prev_args_list rating one_line_summary user_comment comment_id]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# user session tracking
set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]
ec_create_new_session_if_necessary [export_entire_form_as_url_vars]
# type2

# see if the review is already in there, meaning they pushed reload,
# in which case, just show the thank you message, otherwise insert the
# review
if { [database_to_tcl_string $db "select count(*) from ec_product_comments where comment_id = $comment_id"] == 0 } {
    ns_db dml $db "insert into ec_product_comments
(comment_id, product_id, user_id, user_comment, one_line_summary, rating, comment_date, last_modified, last_modifying_user, modified_ip_address)
values
($comment_id, $product_id, $user_id, '$QQuser_comment', '$QQone_line_summary', $rating, sysdate, sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')
"
}

set product_name [database_to_tcl_string $db "select product_name from ec_products where product_id=$product_id"]
set comments_need_approval [ad_parameter ProductCommentsNeedApprovalP ecommerce]
set system_owner_email [ec_system_owner]
set product_link "product.tcl?[export_url_vars product_id]"

ad_return_template