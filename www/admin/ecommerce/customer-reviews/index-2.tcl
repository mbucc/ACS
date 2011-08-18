# $Id: index-2.tcl,v 3.0 2000/02/06 03:17:24 ron Exp $
set_the_usual_form_variables
# approved_p or product_id

set db [ns_db gethandle]

if { [info exists approved_p] } {
    if { $approved_p == "null" } {
	set review_status "Not Yet Approved/Disapproved"
	set query_end "and approved_p is null"
    } elseif { $approved_p == "t" } {
	set review_status "Approved"
	set query_end "and approved_p='t'"
    } elseif { $approved_p == "f" } {
	set review_status "Disapproved"
	set query_end "and approved_p='f'"
    } else {
	set review_status ""
	set query_end ""
    }

    set page_title "$review_status Reviews"
    set navbar [ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Customer Reviews"] "$review_status Reviews"]
    set return_url "index-2.tcl?[export_url_vars approved_p]"

} elseif { [info exists product_id] } {
    set product_name [ec_product_name $product_id]
    set page_title $product_name
    set navbar [ad_admin_context_bar [list "../" "Ecommerce"] [list "../products/index.tcl" "Products"] [list "../products/one.tcl?product_id=$product_id" "One"] "Customer Reviews"]
    set query_end "and p.product_id=$product_id"
    set return_url "index-2.tcl?[export_url_vars product_id]"
}

ReturnHeaders
ns_write "[ad_admin_header $page_title]

<h2>$page_title</h2>

$navbar

<hr>

<ul>
"

# Set audit variables
# audit_id_column, return_url, audit_tables, main_tables
set audit_id_column "comment_id"
set audit_tables [list ec_product_comments_audit]
set main_tables [list ec_product_comments]


set selection [ns_db select $db "select c.comment_id, c.product_id, c.user_id, c.user_comment, c.one_line_summary, c.rating, p.product_name, u.email, c.comment_date, c.approved_p
from ec_product_comments c, ec_products p, users u
where c.product_id = p.product_id
and c. user_id = u.user_id 
$query_end
order by c.comment_date desc
"]


set review_counter 0

while { [ns_db getrow $db $selection] } {
    incr review_counter
    set_variables_after_query
    ns_write "<li>[util_AnsiDatetoPrettyDate $comment_date]<br>
    <a href=\"../products/one.tcl?[export_url_vars product_id]\">$product_name</a><br>
    <a href=\"/admin/users/one.tcl?[export_url_vars user_id]\">$email</a> [ec_display_rating $rating]<br>
    <b>$one_line_summary</b><br>
    [ns_quotehtml $user_comment]
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

    # Set audit variables
    # audit_name, audit_id
    set audit_name "Customer Review $one_line_summary"
    set audit_id $comment_id

    ns_write "\[<a href=\"approval-change.tcl?approved_p=t&[export_url_vars comment_id return_url]\">Approve</a> | <a href=\"approval-change.tcl?approved_p=f&[export_url_vars comment_id return_url]\">Disapprove</a> | <a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>\]
    <p>
    "
}

if { $review_counter == 0 } {
    ns_write "No reviews were found.\n"
}

ns_write "</ul>

[ad_admin_footer]
"
