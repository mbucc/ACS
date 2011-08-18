# $Id: shopping-cart-save-2.tcl,v 3.0.4.1 2000/04/28 15:10:04 carsten Exp $
# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]

if { $user_session_id == 0 } {
    ns_return 200 text/html "[ad_header "No Cart Found"]<h2>No Shopping Cart Found</h2>
    <p>
    We could not find any shopping cart for you.  This may be because you have cookies 
    turned off on your browser.  Cookies are necessary in order to have a shopping cart
    system so that we can tell which items are yours.

    <p>
    <i>In Netscape 4.0, you can enable cookies from Edit -> Preferences -> Advanced. <br>

    In Microsoft Internet Explorer 4.0, you can enable cookies from View -> 
    Internet Options -> Advanced -> Security. </i>

    <p>

    [ec_continue_shopping_options $db]
    "
    return
}

# set the user_id of the order so that we'll know who it belongs to
# and remove the user_session_id so that they can't mess with their
# saved order (until they retrieve it, of course)

ns_db dml $db "update ec_orders set user_id=$user_id, user_session_id=null, saved_p='t'
where user_session_id=$user_session_id and order_state='in_basket'"

# this should have only updated 1 row, or 0 if they reload, which is fine

ad_return_template
