#  www/ecommerce/gift-certificate-thank-you.tcl
ad_page_contract {
 the user is redirected to this page from gift-certificate-finalize-order.tcl if
 their gift certificate order has succeeded

 this page displays a thank you message
  @author
  @creation-date
  @cvs-id gift-certificate-thank-you.tcl,v 3.1.10.4 2000/08/17 21:23:07 seb Exp
} {
}



set home_page "[ec_insecure_url][ad_parameter EcommercePath ecommerce]index"



ad_return_template
