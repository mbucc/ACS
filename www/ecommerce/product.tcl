# $Id: product.tcl,v 3.0 2000/02/06 03:39:33 ron Exp $
# product.tcl
#
# by eveander@arsdigita.com June 1999
# 
# display a single product and possibly comments on that
# product or professional reviews

set_the_usual_form_variables

# product_id required; optional: offer_code and comments_sort_by
# possibly usca_p

# default to empty string (date)
if { ![info exists comments_sort_by] } {
    set comments_sort_by ""
}

# we don't need them to be logged in, but if they are they might get a lower price
set user_id [ad_verify_and_get_user_id]

# user sessions:
# 1. get user_session_id from cookie
# 2. if user has no session (i.e. user_session_id=0), attempt to set it if it hasn't been
#    attempted before
# 3. if it has been attempted before,
#    (a) if they have no offer_code, then do nothing
#    (b) if they have a offer_code, tell them they need cookies on if they
#        want their offer price
# 4. Log this product_id into the user session

set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]

ec_create_new_session_if_necessary [export_url_vars product_id offer_code] cookies_are_not_required

# valid offer codes must be <= 20 characters, so if it's more than 20 characters, pretend
# it isn't there
if { [info exists offer_code] && [string length $offer_code] <= 20 } {
    ad_return_complaint 1 "You need to have cookies turned on in order to have special offers take effect (we use cookies to remember that you are a recipient of this special offer.
    <p>
    Please turn on cookies in your browser, or if you don't wish to take advantage of this offer, you can still <a href=\"index.tcl\">continue shopping at [ec_system_name]</a>"
    return
}

if { [string compare $user_session_id "0"] != 0 } {
    ns_db dml $db "insert into ec_user_session_info (user_session_id, product_id) values ($user_session_id, $product_id)"
}


if { [info exists offer_code] && [string compare $user_session_id "0"] != 0} {
    # insert into or update ec_user_session_offer_codes
    if { [database_to_tcl_string $db "select count(*) from ec_user_session_offer_codes where user_session_id=$user_session_id and product_id=$product_id"] == 0 } {
	ns_db dml $db "insert into ec_user_session_offer_codes (user_session_id, product_id, offer_code) values ($user_session_id, $product_id, '[DoubleApos $offer_code]')"
    } else {
	ns_db dml $db "update ec_user_session_offer_codes set offer_code='[DoubleApos $offer_code]' where user_session_id=$user_session_id and product_id=$product_id"
    }
}

if { ![info exists offer_code] && [string compare $user_session_id "0"] != 0} {
    set offer_code [database_to_tcl_string_or_null $db "select offer_code from ec_user_session_offer_codes where user_session_id=$user_session_id and product_id=$product_id"]
}

if { ![info exists offer_code] } {
    set offer_code ""
}

set currency [ad_parameter Currency ecommerce]
set allow_pre_orders_p [ad_parameter AllowPreOrdersP ecommerce]

# get all the information from both the products table
# and any custom product fields added by this publisher

set selection [ns_db 0or1row $db "select *
from ec_products p, ec_custom_product_field_values v
where p.product_id=$product_id
and p.product_id = v.product_id(+)"]


if { $selection == "" } {
    ns_return 200 text/html "[ad_header "Product Not Found"]The product you have requested was not found in the database.  Please contact <a href=\"mailto:[ec_system_owner]\"><address>[ec_system_owner]</address></a> to report the error."
    return
}

set_variables_after_query


if { ![empty_string_p $template_id] } {

    # Template specified by Url

    set template [database_to_tcl_string $db "select template from ec_templates where template_id=$template_id"]

} else {

    # Template specified by Product category

    set template_list [database_to_tcl_list $db "
SELECT template FROM ec_templates t, ec_category_template_map ct, ec_category_product_map cp
 WHERE t.template_id = ct.template_id
   AND ct.category_id = cp.category_id
   AND cp.product_id = $QQproduct_id"]

    set template [lindex $template_list 0]

    if [empty_string_p $template] {

	# Template specified by... well, just use the default

	set template [database_to_tcl_string $db "select template from ec_templates where template_id=(select default_template from ec_admin_settings)"]
    }
}

ReturnHeaders
ns_write [ns_adp_parse -string $template]
