# index.tcl<2>

ad_page_contract {
    @author
    @creation-date
    @cvs-id index.tcl,v 3.1.6.7 2000/09/22 01:34:50 kevin Exp
} {
}



append doc_body "[ad_admin_header "Customer Reviews"]

<h2>Customer Reviews</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "Customer Reviews"]

<hr>
"

if {[ad_parameter ProductCommentsNeedApprovalP ecommerce]} {
    append doc_body "Comments must be approved before they will appear on the web site."
} else {
    append doc_body "Your ecommerce system is set up so that comments automatically appear on the web site, unless you specifically Disapprove them.  Even though it's not necessary, you may also wish to specifically Approve comments so that you can distinguish them from comments that you have not yet looked at."
}

append doc_body "
<ul>
"



set sql "select approved_p, count(*) as n_reviews
from ec_product_comments
group by approved_p
order by approved_p desc"

db_foreach get_approved_reviews $sql {
    
    if [empty_string_p $approved_p] {
	set passthrough_approved_p "null"
	set anchor_value "Not Yet Approved/Disapproved Customer Reviews"
    } elseif { $approved_p == "t" } {
	set passthrough_approved_p "t"
	set anchor_value "Approved Reviews"
    } elseif { $approved_p == "f" } {
	set passthrough_approved_p "f"
	set anchor_value "Disapproved Reviews"
    } else {
	ns_log Error "/admin/ecommerce/customer-reviews/index.tcl found unrecognized approved_p value of \"$approved_p\""
	# note that we'll probably also get a Tcl error below
    }
    append doc_body "<li><a href=\"index-2?approved_p=$passthrough_approved_p\">$anchor_value</a> ($n_reviews)\n\n<p>\n\n"
}

db_release_unused_handles

set table_names_and_id_column [list ec_product_comments ec_product_comments_audit comment_id]

append doc_body "

<p>

<li><a href=\"/admin/ecommerce/audit-tables?[export_url_vars table_names_and_id_column]\">Audit All Customer Reviews</a>

</ul>

[ad_admin_footer]
"


doc_return  200 text/html $doc_body
