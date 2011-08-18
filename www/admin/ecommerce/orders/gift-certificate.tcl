# $Id: gift-certificate.tcl,v 3.0 2000/02/06 03:19:10 ron Exp $
set_the_usual_form_variables
# gift_certificate_id

ReturnHeaders

ns_write "[ad_admin_header "One Gift Certificate"]

<h2>One Gift Certificate</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "gift-certificates.tcl" "Gift Certificates"] "One"]

<hr>
<blockquote>
"

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select c.*, i.first_names || ' ' || i.last_name as issuer, i.user_id as issuer_user_id, p.first_names || ' ' || p.last_name as purchaser, p.user_id as purchaser_user_id, gift_certificate_amount_left(c.gift_certificate_id) as amount_left, decode(sign(sysdate-expires),1,'t',0,'t','f') as expired_p, v.first_names as voided_by_first_names, v.last_name as voided_by_last_name, o.first_names || ' ' || o.last_name as owned_by
from ec_gift_certificates c, users i, users p, users v, users o
where c.issued_by=i.user_id(+)
and c.purchased_by=p.user_id(+)
and c.voided_by=v.user_id(+)
and c.user_id=o.user_id(+)
and c.gift_certificate_id=$gift_certificate_id"]


if { [empty_string_p $selection] } {
    ns_write "Not Found. [ad_admin_footer]"
    return
}

set_variables_after_query

ns_write "
<table>
<tr><td>Gift Certificate ID &nbsp;&nbsp;&nbsp;</td><td>$gift_certificate_id</td></tr>
<tr><td>Amount Left</td><td>[ec_pretty_price $amount_left] <font size=-1>(out of [ec_pretty_price $amount])</font></td></tr>
"
if { ![empty_string_p $issuer_user_id] } {
    ns_write "<tr><td>Issued By</td><td><a href=\"/admin/users/one.tcl?user_id=$issuer_user_id\">$issuer</a> on [util_AnsiDatetoPrettyDate $issue_date]</td></tr>
    <tr><td>Issued To</td><td><a href=\"/admin/users/one.tcl?user_id=$user_id\">$owned_by</a></td><tr>"
} else {
    ns_write "<tr><td>Purchased By</td><td><a href=\"/admin/users/one.tcl?user_id=$purchaser_user_id\">$purchaser</a> on [util_AnsiDatetoPrettyDate $issue_date]</td></tr>
    <tr><td>Sent To</td><td>$recipient_email</td></tr>
    "

    if { ![empty_string_p $user_id] } {
	ns_write "<tr><td>Claimed By</td><td><a href=\"/admin/users/one.tcl?user_id=$user_id\">$owned_by</a> on [util_AnsiDatetoPrettyDate $claimed_date]</td></tr>"
    }

}
ns_write "<tr><td>[ec_decode $expired_p "t" "Expired" "Expires"]</td><td>[ec_decode $expires "" "never" [util_AnsiDatetoPrettyDate $expires]]</td></tr>
"

if { $gift_certificate_state == "void" } {
    ns_write "<tr><td><font color=red>Voided</font></td><td>[util_AnsiDatetoPrettyDate $voided_date] by <a href=\"/admin/users/one.tcl?user_id=$voided_by\">$voided_by_first_names $voided_by_last_name</a> because: $reason_for_void</td></tr>"
}


ns_write "</table>"

if { $expired_p == "f" && $amount_left > 0 && $gift_certificate_state != "void"} {
    ns_write "<font size=-1>(<a href=\"gift-certificate-void.tcl?[export_url_vars gift_certificate_id]\">void this</a>)</font>
    "
}



ns_write "</blockquote>
[ad_admin_footer]
"