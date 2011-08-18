# $Id: review-submit-2.tcl,v 3.0.4.1 2000/04/28 15:10:02 carsten Exp $
set_the_usual_form_variables
# product_id, rating, one_line_summary, user_comment
# possibly usca_p

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set exception_text ""
set exception_count 0

if { ![info exists rating] || [empty_string_p $rating] } {
    append exception_text "<li>Please select a rating for the product.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# user session tracking
set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]
ec_create_new_session_if_necessary [export_entire_form_as_url_vars]
# type2

set product_name [database_to_tcl_string $db "select product_name from ec_products where product_id=$product_id"]
set comment_id [database_to_tcl_string $db "select ec_product_comment_id_sequence.nextval from dual"]

set hidden_form_variables [export_form_vars product_id rating one_line_summary user_comment comment_id]

set review_as_it_will_appear "<b><a href=\"/shared/community-member.tcl?[export_url_vars user_id]\">[database_to_tcl_string $db "select email from users where user_id=$user_id"]</a></b> 
rated this product  
[ec_display_rating $rating] on <i>[database_to_tcl_string $db "select to_char(sysdate,'Day Month DD, YYYY') from dual"]</i> and wrote:<br>
<b>$one_line_summary</b><br>
[ec_display_as_html $user_comment]
"

set system_name [ad_system_name]

ad_return_template