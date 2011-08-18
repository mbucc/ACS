# $Id: gift-certificate-add.tcl,v 3.0 2000/02/06 03:17:46 ron Exp $
set_the_usual_form_variables
# user_id, amount, expires

# make sure there's an amount
if { ![info exists amount] || [empty_string_p $amount] } {
    ad_return_complaint 1 "<li>You forgot to specify an amount."
    return
}

ReturnHeaders

set page_title "Confirm New Gift Certificate"
ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>
"

set db [ns_db gethandle]
set expiration_to_print [database_to_tcl_string $db "select [ec_decode $expires "" "null" $expires] from dual"]
set expiration_to_print [ec_decode $expiration_to_print "" "never" [util_AnsiDatetoPrettyDate $expiration_to_print]]

ns_write "Please confirm that you wish to add [ec_pretty_price $amount [ad_parameter Currency ecommerce]] to
<a href=\"/admin/users/one.tcl?user_id=$user_id\">[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$user_id"]</a>'s gift certificate account (expires $expiration_to_print).

<p>

<form method=post action=gift-certificate-add-2.tcl>
[export_form_vars user_id amount expires]
<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"