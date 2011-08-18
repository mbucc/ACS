# $Id: edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:56 carsten Exp $
set_the_usual_form_variables
# base_shipping_cost, default_shipping_per_item, weight_shipping_cost, add_exp_base_shipping_cost, add_exp_amount_per_item, add_exp_amount_by_weight

set db [ns_db gethandle]

ns_db dml $db "update ec_admin_settings
set base_shipping_cost = '$base_shipping_cost',
default_shipping_per_item = '$default_shipping_per_item',
weight_shipping_cost = '$weight_shipping_cost',
add_exp_base_shipping_cost = '$add_exp_base_shipping_cost',
add_exp_amount_per_item = '$add_exp_amount_per_item',
add_exp_amount_by_weight = '$add_exp_amount_by_weight'"

ad_returnredirect "index.tcl"