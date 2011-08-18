# $Id: ecommerce-user-contributions-summary.tcl,v 3.0 2000/02/06 03:13:25 ron Exp $
#
# ecommerce-user-contributions-summary.tcl
#
# by philg@mit.edu on November 1, 1999
#
# exists only to show the site owner a user's activities
# on the site in the ecommerce system
#

util_report_library_entry

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Ecommerce" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Ecommerce" ecommerce_user_contributions 0]
}

proc_doc ecommerce_user_contributions {db user_id purpose} {Returns list items, one for each classified posting} {
    if { $purpose != "site_admin" } {
	return [list]
    }
    if ![ad_parameter EnabledP ecommerce 0] {
	return [list]
    }
    set moby_string ""
    append moby_string "<ul>
    <li>Ecommerce User Classes: [ec_user_class_display $db $user_id t]
    
    <p>

    <li><a href=\"/admin/ecommerce/customer-service/gift-certificates.tcl?user_id=$user_id\">Gift Certificates</a> (balance [ec_pretty_price [database_to_tcl_string $db "select ec_gift_certificate_balance($user_id) from dual"]])
    </ul>

    <h4>Addresses</h4>
    <ul>
    "

    set address_id_list [database_to_tcl_list $db "select address_id
from ec_addresses where user_id = $user_id"]

    foreach address_id $address_id_list  {
	append moby_string "<li>[ec_display_as_html [ec_pretty_mailing_address_from_ec_addresses $db $address_id]]<p>\n"
    }

    append moby_string "
    </ul>

    <h4>Order History</h4>

    [ec_all_orders_by_one_user $db $user_id]

    <h4>Customer Service History</h4>
    <ul>
    <li><a href=\"/admin/ecommerce/customer-service/interaction-summary.tcl?user_id=$user_id\">Interaction Summary</a>
    <li>Individual Issues:
    [ec_all_cs_issues_by_one_user $db $user_id]
    </ul>

    <h4>Product Reviews</h4>
    <ul>
    "

    set selection [ns_db select $db "select c.comment_id, p.product_name, comment_date
    from ec_product_comments c, ec_products p
    where c.product_id = p.product_id
    and user_id = $user_id"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append moby_string "<li>[util_AnsiDatetoPrettyDate $comment_date] : <a href=\"/admin/ecommerce/customer-reviews/one.tcl?[export_url_vars comment_id]\">$product_name</a>\n"
    }

    append moby_string "</ul>
    "
    if [empty_string_p $moby_string] {
	return [list]
    } else {
	return [list 0 "Ecommerce" $moby_string]
    }

}
util_report_successful_library_load
