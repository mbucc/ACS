#  www/admin/ecommerce/shipping-costs/edit.tcl
ad_page_contract {
    @param base_shipping_cost
    @param default_shipping_per_item
    @param weight_shipping_cost
    @param add_exp_base_shipping_cost
    @param add_exp_amount_per_item
    @param add_exp_amount_by_weight
    
    @author
    @creation-date
    @cvs-id edit.tcl,v 3.1.6.6 2001/01/15 20:09:51 kevin Exp
} {
    base_shipping_cost
    default_shipping_per_item
    weight_shipping_cost
    add_exp_base_shipping_cost
    add_exp_amount_per_item
    add_exp_amount_by_weight
}

#

# error checking:
# anything on this page can be blank (if *everything* is blank, it means
# that the shipping costs are included in the costs of the items, which
# is fine)
# however, if something is not blank, I have to make sure that it's
# purely numeric (0-9 and .)
# I don't allow both default_shipping_per_item and weight_shipping_cost
# to be filled in -- it's one or the other, so there's no question about
# what takes precedence

set exception_count 0
set exception_text ""

if { [exists_and_not_null base_shipping_cost]} {
    if {![regexp {^[0-9|.]+$} $base_shipping_cost]} {
	incr exception_count
	append exception_text "<li>The Base Cost must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
    if {[regexp {^[.]$} $base_shipping_cost]} {
	incr exception_count
	append exception_text "<li>The Base Cost must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
}

if { [exists_and_not_null default_shipping_per_item]} {
    if {![regexp {^[0-9|.]+$} $default_shipping_per_item]} {
	incr exception_count
	append exception_text "<li>The Default Amount Per Item must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
    if {[regexp {^[.]$} $default_shipping_per_item]} {
	incr exception_count
	append exception_text "<li>The Default Amount Per Item must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
}

if { [exists_and_not_null weight_shipping_cost]} { 
    if {![regexp {^[0-9|.]+$} $weight_shipping_cost]} {
	incr exception_count
	append exception_text "<li>The Weight Charge must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
    if {[regexp {^[.]$} $weight_shipping_cost]} {
	incr exception_count
	append exception_text "<li>The Weight Charge must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
}

if { [exists_and_not_null add_exp_base_shipping_cost]} {
    if {![regexp {^[0-9|.]+$} $add_exp_base_shipping_cost]} {
	incr exception_count
	append exception_text "<li>The Additional Base Cost must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
    if {[regexp {^[.]$} $add_exp_base_shipping_cost]  } {
	incr exception_count
	append exception_text "<li>The Additional Base Cost must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
}

if { [exists_and_not_null add_exp_amount_per_item]} {
    if {![regexp {^[0-9|.]+$} $add_exp_amount_per_item]} {
	incr exception_count
	append exception_text "<li>Additional Amount Per Item must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
    if {[regexp {^[.]$}  $add_exp_amount_per_item] } {
	incr exception_count
	append exception_text "<li>Additional Amount Per Item must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
}

if { [exists_and_not_null add_exp_amount_by_weight]} {
    if {![regexp {^[0-9|.]+$} $add_exp_amount_by_weight]} {
	incr exception_count
	append exception_text "<li>The Additional Amount by Weight must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
    if {[regexp {^[.]$} $add_exp_amount_by_weight] } {
	incr exception_count
	append exception_text "<li>The Additional Amount by Weight must be a number (like 4.95).  It cannot contain any other characters than numerals or a decimal point."
    }
}

if { [exists_and_not_null default_shipping_per_item] && [exists_and_not_null weight_shipping_cost] } {
    incr exception_count
    append exception_text "<li>You can't fill in both Default Amount Per Item and Weight Charge.  Please choose one or the other (the method you choose will be used to determine the shipping price if the price isn't explicitly set in the \"Shipping Price\" field)."
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# error checking done


set page_html "[ad_admin_header "Confirm Shipping Costs"]

<h2>Confirm Shipping Costs</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Shipping Costs"] "Edit"]

<hr>

<b>Please confirm that you want shipping to be charged as follows:</b>

<blockquote>
[ec_shipping_cost_summary $base_shipping_cost $default_shipping_per_item $weight_shipping_cost $add_exp_base_shipping_cost $add_exp_amount_per_item $add_exp_amount_by_weight]
</blockquote>

<form method=post action=edit-2>
[export_form_vars base_shipping_cost default_shipping_per_item weight_shipping_cost add_exp_base_shipping_cost add_exp_amount_per_item add_exp_amount_by_weight]

<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"
doc_return  200 text/html $page_html
