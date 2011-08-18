# $Id: gift-certificate-thank-you.tcl,v 3.1 2000/03/07 03:51:51 eveander Exp $
# the user is redirected to this page from gift-certificate-finalize-order.tcl if
# their gift certificate order has succeeded

# this page displays a thank you message

set home_page "[ec_insecure_url][ad_parameter EcommercePath ecommerce]index.tcl"

set db [ns_db gethandle]

ad_return_template