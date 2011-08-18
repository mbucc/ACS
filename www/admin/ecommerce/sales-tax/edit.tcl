# $Id: edit.tcl,v 3.0 2000/02/06 03:21:26 ron Exp $
# The only form element is a usps_abbrev multiple select.
# If I end up adding something else, I'll have to modify
# below and use it in conjunction with set_form_variables
set form [ns_getform]

if [catch {set form_size [ns_set size $form]} ] {
    ad_return_complaint 1 "<li>Please choose at least one state."
    return
}
set form_counter 0

set usps_abbrev_list [list]
while { $form_counter < $form_size} {
    lappend usps_abbrev_list [ns_set value $form $form_counter]
    incr form_counter
}

ReturnHeaders
ns_write "[ad_admin_header "Sales Tax, Continued"]

<h2>Sales Tax, Continued</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Sales Tax"] "Edit"]

<hr>

Please specify the sales tax rates below for each state listed and whether tax
is charged on shipping in that state:

<p>

<form method=post action=edit-2.tcl>
[export_form_vars usps_abbrev_list]

<ul>
"

set db [ns_db gethandle]
foreach usps_abbrev $usps_abbrev_list {
    ns_write "<li><b>[ad_state_name_from_usps_abbrev $db $usps_abbrev]:</b>
<blockquote>
Tax rate <input type=text name=${usps_abbrev}_tax_rate size=4 value=\"[database_to_tcl_string_or_null $db "select tax_rate*100 from ec_sales_tax_by_state where usps_abbrev='$usps_abbrev'"]\">%<br>
Charge tax on shipping? 
"

set shipping_p [database_to_tcl_string_or_null $db "select shipping_p from ec_sales_tax_by_state where usps_abbrev='$usps_abbrev'"]
if { [empty_string_p $shipping_p] || $shipping_p == "t" } {
    ns_write "<input type=radio name=${usps_abbrev}_shipping_p value=t checked>Yes
    &nbsp; <input type=radio name=${usps_abbrev}_shipping_p value=f>No
    "
} else {
    ns_write "<input type=radio name=${usps_abbrev}_shipping_p value=t>Yes
    &nbsp; <input type=radio name=${usps_abbrev}_shipping_p value=f checked>No
    "
}

ns_write "</blockquote>
"
}

ns_write "</ul>

<center>
<input type=submit value=\"Submit\">
</center>

</form>
[ad_admin_footer]
"


