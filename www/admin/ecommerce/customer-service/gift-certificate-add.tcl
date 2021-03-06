# gift-certificate-add.tcl

ad_page_contract { 
    @param user_id
    @param amount
    @param expires

    @author
    @creation-date
    @cvs-id gift-certificate-add.tcl,v 3.1.6.6 2000/09/22 01:34:51 kevin Exp
} {
    user_id
    amount
    expires
}




# make sure there's an amount
if { ![info exists amount] || [empty_string_p $amount] } {
    ad_return_complaint 1 "<li>You forgot to specify an amount."
    return
}



set page_title "Confirm New Gift Certificate"
append doc_body "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>
"


set expiration_to_print [db_string get_exipre_from_Db "select [ec_decode $expires "" "null" $expires] from dual"]
set expiration_to_print [ec_decode $expiration_to_print "" "never" [util_AnsiDatetoPrettyDate $expiration_to_print]]

append doc_body "Please confirm that you wish to add [ec_pretty_price $amount [ad_parameter Currency ecommerce]] to
<a href=\"/admin/users/one?user_id=$user_id\">[db_string get_full_name "select first_names || ' ' || last_name from users where user_id=:user_id"]</a>'s gift certificate account (expires $expiration_to_print).

<p>

<form method=post action=gift-certificate-add-2>
[export_form_vars user_id amount expires]
<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"



doc_return  200 text/html $doc_body






