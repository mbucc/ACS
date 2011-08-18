# $Id: gift-certificate-void.tcl,v 3.0.4.1 2000/04/28 15:08:44 carsten Exp $
set_the_usual_form_variables
# gift_certificate_id

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

ReturnHeaders

set page_title "Void Gift Certificate"
ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Orders"] [list "gift-certificates.tcl" "Gift Certificates"] "Void One"]

<hr>
Please explain why you are voiding this gift certificate:

<form method=post action=gift-certificate-void-2.tcl>
[export_form_vars gift_certificate_id]

<blockquote>
<textarea wrap name=reason_for_void rows=3 cols=50></textarea>
</blockquote>

<center>
<input type=submit value=\"Continue\">
</center>

</form>

[ad_admin_footer]
"
