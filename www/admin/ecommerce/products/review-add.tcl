#  www/admin/ecommerce/products/review-add.tcl
ad_page_contract {
  Review confirmation page.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id review-add.tcl,v 3.1.6.4 2001/01/12 18:47:38 khy Exp
} {
  product_id:integer,notnull
  publication
  display_p
  review:html
  author_name
  review_date:array,date
}

page_validation {
#  ec_date_widget_validate review_date
}

set product_name [ec_product_name $product_id]

doc_body_append "[ad_admin_header "Confirm Review of $product_name"]

<h2>Confirm Review of $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] [list "reviews.tcl?[export_url_vars product_id product_name]" "Professional Reviews"] "Confirm Review"]

<hr>

<table>
<tr>
<td>Summary</td>
<td>[ec_product_review_summary $author_name $publication [ec_date_text review_date]]</td>
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
"


set review_id [db_string review_id_select "select ec_product_review_id_sequence.nextval from dual"]

doc_body_append "<form method=post action=review-add-2>
[export_form_vars product_id publication display_p review author_name]
[export_form_vars -sign review_id]
<input type=hidden name=review_date value=\"[ec_date_text review_date]\">

<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"
