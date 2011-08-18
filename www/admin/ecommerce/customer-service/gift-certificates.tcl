# $Id: gift-certificates.tcl,v 3.0 2000/02/06 03:17:51 ron Exp $
set_the_usual_form_variables
# user_id

ReturnHeaders

set page_title "Gift Certificates"
ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>
"

set db [ns_db gethandle]

ns_write "<b>Customer:</b> <a href=\"/admin/users/one.tcl?user_id=$user_id\">[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$user_id"]</a>

<p>

<b>Gift Certificate Account Balance: [ec_pretty_price [database_to_tcl_string $db "select ec_gift_certificate_balance($user_id) from dual"]]</b>

<p>
<b>Grant a gift certificate</b>
<blockquote>
<form method=post action=gift-certificate-add.tcl>
[export_form_vars user_id]
<table>
<tr>
<td>Amount</td>
<td><input type=text name=amount size=5> ([ad_parameter Currency ecommerce])</td>
<td rowspan=2><input type=submit value=\"Grant\"></td>
</tr>
<tr>
<td>Expires</td>
<td>[ec_gift_certificate_expires_widget "in 1 year"]</td>
</tr>
</table>
</form>
</blockquote>

"

set selection [ns_db select $db "select c.*, i.first_names || ' ' || i.last_name as issuer, i.user_id as issuer_user_id, p.first_names || ' ' || p.last_name as purchaser, p.user_id as purchaser_user_id, gift_certificate_amount_left(c.gift_certificate_id) as amount_left, decode(sign(sysdate-expires),1,'t',0,'t','f') as expired_p, v.first_names as voided_by_first_names, v.last_name as voided_by_last_name
from ec_gift_certificates c, users i, users p, users v
where c.issued_by=i.user_id(+)
and c.purchased_by=p.user_id(+)
and c.voided_by=v.user_id(+)
and c.user_id=$user_id
order by expired_p, decode(amount_left,0,1,0), decode(gift_certificate_state,'void',1,0), gift_certificate_id"]

set gift_certificate_counter 0
set current_printed 0
set old_printed 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $current_printed == 0 && $expired_p == "f" && $amount_left > 0 && $gift_certificate_state != "void"} {
	ns_write "<b>Currently Available Gift Certificates</b>
	<blockquote>
	"
	set current_printed 1
    } elseif { $old_printed == 0 && ($expired_p == "t" || $amount_left == 0 || $gift_certificate_state == "void") } {
	if { $current_printed == 1 } {
	    ns_write "</blockquote>"
	}
	ns_write "<b>Expired or Used Gift Certificates</b>
	<blockquote>
	"
	set old_printed 1
    }

    incr gift_certificate_counter

    ns_write "
    <table>
    <tr><td>Gift Certificate ID &nbsp;&nbsp;&nbsp;</td><td>$gift_certificate_id</td></tr>
    <tr><td>Amount Left</td><td>[ec_pretty_price $amount_left] <font size=-1>(out of [ec_pretty_price $amount])</font></td></tr>
    <tr><td>Issue Date</td><td>[util_AnsiDatetoPrettyDate $issue_date]</td></tr>
    "
    if { ![empty_string_p $issuer_user_id] } {
	ns_write "<tr><td>Issued By</td><td><a href=\"/admin/users/one.tcl?user_id=$issuer_user_id\">$issuer</a></td></tr>"
    } else {
	ns_write "<tr><td>Purchased By</td><td><a href=\"/admin/users/one.tcl?user_id=$purchaser_user_id\">$purchaser</a></td></tr>"
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

    ns_write "<p>
    "
}

if { $current_printed == 1 || $old_printed == 1 } {
    ns_write "</blockquote>"
}

ns_write "[ad_admin_footer]
"