# $Id: sale-price-edit-2.tcl,v 3.0 2000/02/06 03:20:55 ron Exp $
set_the_usual_form_variables
# sale_price_id, product_id, product_name, sale_price, sale_name, sale_begins (in parts),
# sale_ends (in parts), offer_code_needed (no, yes_supplied, yes_generate) and maybe offer_code

set exception_count 0
set exception_text ""

if { ![info exists sale_price] || [empty_string_p $sale_price] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the sale price\n"
} elseif { [regexp {[^0-9\.]} $sale_price] } {
    incr exception_count
    append exception_text "<li>The sale price must be a number."
}

if { ![info exists sale_name] || [empty_string_p $sale_name] } {
    # just set it to "Sale Price" -- don't bother giving them an error
    set sale_name "Sale Price"
}

# deal w/dates
set form [ns_getform]
if [catch  { ns_dbformvalue $form sale_begins datetime sale_begins} errmsg ] {
    incr exception_count
    append exception_text "<li>The date that the sale begins was specified in the wrong format.  It should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.sale%5fbegins.year]] < 4 } {
    incr exception_count
    append exception_text "<li>The year that the sale begins needs to contain 4 digits.\n"
}

if [catch  { ns_dbformvalue $form sale_ends datetime sale_ends} errmsg ] {
    incr exception_count
    append exception_text "<li>The date that the sale ends was specified in the wrong format.  It should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.sale%5fends.year]] < 4 } {
    incr exception_count
    append exception_text "<li>The year that the sale ends needs to contain 4 digits.\n"
}

if { [info exists sale_begins] && [empty_string_p $sale_begins] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the date that the sale begins.\n"
}

if { [info exists sale_ends] && [empty_string_p $sale_ends] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the date that the sale ends.\n"
}

if { ![info exists offer_code_needed] || [empty_string_p $offer_code_needed] } {
    incr exception_count
    append exception_text "<li>You forgot to specify whether an offer code is needed.\n"
}

if { [info exists offer_code_needed] && $offer_code_needed == "yes_supplied" && (![info exists offer_code] || [empty_string_p $offer_code]) } {
    incr exception_count
    append exception_text "<li>You forgot to specify an offer code.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# error checking done

# if offer_code_needed is yes_generate, I need to generate a offer_code
if { $offer_code_needed == "yes_generate" } {
    set offer_code [ec_generate_random_string 8]
}

# for the case where no offer code is required to get the sale price
if { ![info exists offer_code] } {
    set offer_code ""
}

ReturnHeaders
ns_write "[ad_admin_header "Confirm Sale Price for $product_name"]

<h2>Confirm Sale Price for $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Confirm Sale Price"]

<hr>
"

set currency [ad_parameter Currency ecommerce]

set db [ns_db gethandle]

ns_write "<table>
<tr>
<td>Sale Price</td>
<td>[ec_pretty_price $sale_price $currency]</td>
</tr>
<tr>
<td>Name</td>
<td>$sale_name</td>
</tr>
<tr>
<td>Sale Begins</td>
<td>[util_AnsiDatetoPrettyDate [lindex [split $sale_begins " "] 0]] [lindex [split $sale_begins " "] 1]</td>
</tr>
<tr>
<td>Sale Ends</td>
<td>[util_AnsiDatetoPrettyDate [lindex [split $sale_ends " "] 0]] [lindex [split $sale_ends " "] 1]</td>
</tr>
<tr>
<td>Offer Code</td>
<td>[ec_decode $offer_code "" "None Needed" $offer_code]</td>
</tr>
</table>

<form method=post action=sale-price-edit-3.tcl>
[export_form_vars sale_price_id product_id product_name sale_price sale_name sale_begins sale_ends offer_code]
<center>
<input type=submit value=\"Confirm\">
</center>

</form>
[ad_admin_footer]
"