# $Id: account.tcl,v 3.1.2.1 2000/04/28 15:09:59 carsten Exp $
set_form_variables 0
# possibly usca_p

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set user_session_id [ec_get_user_session_id]

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]
ec_create_new_session_if_necessary
# type1

ec_log_user_as_user_id_for_this_session

set selection [ns_db select $db "select order_id, confirmed_date from ec_orders
where user_id=$user_id
and order_state not in ('in_basket','void','expired')
order by order_id"]

set past_orders ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append past_orders "<li><a href=\"order.tcl?[export_url_vars order_id]\">$order_id</a>; [util_AnsiDatetoPrettyDate $confirmed_date]; [ec_order_status $db_sub $order_id]\n"
}


if { [llength $past_orders] == 0 } {
    append past_orders "You have no orders."
}

# Gift Certificates
# One Entry for each gift certificate
# and the title only, if there is at least one
set selection [ns_db select $db "select 
gift_certificate_id, issue_date, amount
from ec_gift_certificates
where purchased_by=$user_id
and gift_certificate_state in ('authorized','authorized_plus_avs','authorized_minus_avs', 'confirmed')"]

set purchased_gift_certificates ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append purchased_gift_certificates "<li><a href=\"gift-certificate.tcl?[export_url_vars gift_certificate_id]\">$gift_certificate_id</a>; [util_AnsiDatetoPrettyDate $issue_date]; [ec_pretty_price $amount]; [ec_gift_certificate_status $db_sub $gift_certificate_id]\n"
}

if { ![empty_string_p $purchased_gift_certificates] } {
    set purchased_gift_certificates "<h3>Gift Certificates Purchased by You for Others</h3>\n <ul> \n$purchased_gift_certificates\n</ul>"
}


set gift_certificate_balance "[database_to_tcl_string $db "select ec_gift_certificate_balance($user_id) from dual"]"

if { $gift_certificate_balance > 0 } {
    set gift_certificate_sentence_if_nonzero_balance "<li>You have [ec_pretty_price $gift_certificate_balance] in your gift certificate account!"
} else {
    set gift_certificate_sentence_if_nonzero_balance ""
}

# User Classes: this section will only show up if the user is allowed to view them and
# if any user classes exist
set user_classes ""
if { [ad_parameter UserClassUserViewP ecommerce] == 1 && ![empty_string_p [database_to_tcl_string_or_null $db "select 1 from dual where exists (select 1 from ec_user_classes)"]]} {

    set user_classes_to_display [ec_user_class_display $db $user_id]

    append user_classes "<p><li>User Classes: $user_classes_to_display"

    if { [ad_parameter UserClassAllowSelfPlacement ecommerce] } {
	append user_classes " (<a href=\"update-user-classes.tcl\">[ec_decode $user_classes_to_display "" "sign up for one" "update"]</a>)"
    }

    append user_classes "\n"
}

# Mailing Lists
set mailing_lists ""

set selection [ns_db select $db "select 
 ml.category_id, 
 c.category_name,
 ml.subcategory_id, 
 s.subcategory_name, 
 ml.subsubcategory_id,
 ss.subsubcategory_name
from ec_cat_mailing_lists ml, 
 ec_categories c,
 ec_subcategories s,
 ec_subsubcategories ss
where ml.user_id = $user_id
and ml.category_id = c.category_id(+)
and ml.subcategory_id = s.subcategory_id(+)
and ml.subsubcategory_id = ss.subsubcategory_id(+)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append mailing_lists "<li>$category_name [ec_decode $subcategory_name "" "" ": $subcategory_name"] [ec_decode $subsubcategory_name "" "" ": $subsubcategory_name"] (<a href=\"mailing-list-remove.tcl?[export_url_vars category_id subcategory_id subsubcategory_id]\">remove me</a>)"
}

if { [empty_string_p $mailing_lists] } {
    set mailing_lists "<i>You are not currently subscribed to any mailing lists.</i>"
}
set mailing_lists "<h3>Mailing Lists</h3><ul>$mailing_lists</ul>\n"

ad_return_template