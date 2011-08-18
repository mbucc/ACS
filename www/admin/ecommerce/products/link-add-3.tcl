# $Id: link-add-3.tcl,v 3.0.4.1 2000/04/28 15:08:52 carsten Exp $
set_the_usual_form_variables
# action, product_id, product_name, link_product_name, link_product_id

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

if { $action == "both" || $action == "to" } {

    # see if it's already in there
    if { 0 == [database_to_tcl_string $db "select count(*) from ec_product_links where product_a=$link_product_id and product_b=$product_id"] } {
	ns_db dml $db "insert into ec_product_links
	(product_a, product_b, last_modified, last_modifying_user, modified_ip_address)
	values
	($link_product_id, $product_id, sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')
	"
    }
}

if { $action == "both" || $action == "from" } {
    if { 0 == [database_to_tcl_string $db "select count(*) from ec_product_links where product_a=$product_id and product_b=$link_product_id"] } {
	ns_db dml $db "insert into ec_product_links
	(product_a, product_b, last_modified, last_modifying_user, modified_ip_address)
	values
	($product_id, $link_product_id, sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')
	"
    }
}

ns_db dml $db "end transaction"

ad_returnredirect "link.tcl?[export_url_vars product_id product_name]"