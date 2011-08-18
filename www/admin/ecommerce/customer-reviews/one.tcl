# $Id: one.tcl,v 3.0 2000/02/06 03:17:27 ron Exp $
set_the_usual_form_variables
# comment_id

ReturnHeaders

ns_write "[ad_admin_header "One Review"]

<h2>One Review</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Customer Reviews"] "One Review"]

<hr>
<blockquote>
"
set db [ns_db gethandle]

set selection [ns_db 1row $db "select c.product_id, c.user_id, c.user_comment, c.one_line_summary, c.rating, p.product_name, u.email, c.comment_date, c.approved_p
from ec_product_comments c, ec_products p, users u
where c.product_id = p.product_id
and c. user_id = u.user_id 
and c.comment_id=$comment_id"]

set_variables_after_query

ns_write "[util_AnsiDatetoPrettyDate $comment_date]<br>
<a href=\"../products/one.tcl?[export_url_vars product_id]\">$product_name</a><br>
<a href=\"/admin/users/one.tcl?[export_url_vars user_id]\">$email</a> [ec_display_rating $rating]<br>
<b>$one_line_summary</b><br>
$user_comment
<br>
"

if { [info exists product_id] } {
    # then we don't know a priori whether this is an approved review
    ns_write "<b>Review Status: "
    if { $approved_p == "t" } {
	ns_write "Approved</b><br>"
    } elseif { $approved_p == "f" } {
	ns_write "Disapproved</b><br>"
    } else {
	ns_write "Not yet Approved/Disapproved</b><br>"
    }
}

ns_write "\[<a href=\"approval-change.tcl?approved_p=t&[export_url_vars comment_id return_url]\">Approve</a> | <a href=\"approval-change.tcl?approved_p=f&[export_url_vars comment_id return_url]\">Disapprove</a>\]

</blockquote>
[ad_admin_footer]
"
