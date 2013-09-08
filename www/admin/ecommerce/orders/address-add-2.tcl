#  /www/admin/ecommerce/orders/address-add-2.tcl
ad_page_contract {
  Confirm shipping address.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id address-add-2.tcl,v 3.1.6.3 2000/08/16 16:28:51 seb Exp
} {
  order_id:integer,notnull
  attn
  line1
  line2
  city
  {usps_abbrev ""}
  {full_state_name ""}
  zip_code
  {country_code "us"}
  phone
  phone_time
}

doc_body_append "[ad_admin_header "Confirm Shipping Address"]

<h2>Confirm Shipping Address</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index" "Orders"] [list "one?[export_url_vars order_id]" "One Order"] "Confirm Shipping Address"]

<hr>
Please confirm new address:
<blockquote>
"

doc_body_append "

[ec_display_as_html [ec_pretty_mailing_address_from_args $line1 $line2 $city $usps_abbrev $zip_code $country_code $full_state_name $attn $phone $phone_time]]

</blockquote>
<form method=post action=address-add-3>
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
[ad_admin_footer]
"
