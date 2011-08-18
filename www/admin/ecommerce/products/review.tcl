# $Id: review.tcl,v 3.0 2000/02/06 03:20:51 ron Exp $
set_the_usual_form_variables
# review_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from ec_product_reviews where review_id=$review_id"]
set_variables_after_query

set product_name [ec_product_name $product_id]

ReturnHeaders
ns_write "[ad_admin_header "Professional Review of $product_name"]

<h2>Professional Review of $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] [list "reviews.tcl?[export_url_vars product_id]" "Professional Reviews"] "One Review"]

<hr>
<h3>The Review</h3>
<blockquote>
<table>
<tr>
<td>Summary</td>
<td>[ec_product_review_summary $author_name $publication $review_date]</td>
</tr>
<tr>
<td>Display on web site?</td>
<td>[util_PrettyBoolean $display_p]</td>
</tr>
<tr>
<td>Review</td>
<td>$review</td>
</tr>
</table>
</blockquote>

<p>

<h3>Edit this Review</h3>

<blockquote>

<form method=post action=review-edit.tcl>
[export_form_vars review_id product_id]

<table>
<tr>
<td>
Publication
</td>
<td>
<input type=text name=publication size=20 value=\"[philg_quote_double_quotes $publication]\">
</td>
</tr>
<tr>
<td>
Reviewed By
</td>
<td>
<input type=text name=author_name size=20 value=\"[philg_quote_double_quotes $author_name]\">
</td>
</tr>
<tr>
<td>
Reviewed On
</td>
<td>
[ad_dateentrywidget review_date $review_date]
</td>
</tr>
<tr>
<td>
Display on web site?
</td>
<td>
<input type=radio name=display_p value=\"t\" 
[ec_decode $display_p "t" "checked" ""]>Yes &nbsp;
<input type=radio name=display_p value=\"f\"
[ec_decode $display_p "f" "checked" ""]>No
</td>
</tr>
<tr>
<td>
Review<br>
(HTML format)
</td>
<td>
<textarea name=review rows=10 cols=50 wrap>$review</textarea>
</td>
</tr>
</table>

<p>

<center>
<input type=submit value=\"Edit\">
</center>

</form>

</blockquote>

<h3>Audit Review</h3>

<blockquote>
<ul>
"

# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name "$product_name, Review:[ec_product_review_summary $author_name $publication $review_date]"
set audit_id $review_id
set audit_id_column "review_id"
set return_url "[ns_conn url]?[export_url_vars review_id]"
set audit_tables [list ec_product_reviews_audit]
set main_tables [list ec_product_reviews]

ns_write "<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">audit trail</a>

</ul>
</blockquote>

[ad_admin_footer]
"
