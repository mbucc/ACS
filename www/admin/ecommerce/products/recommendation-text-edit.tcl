# $Id: recommendation-text-edit.tcl,v 3.0 2000/02/06 03:20:44 ron Exp $
# recommendation-text-edit.tcl
#
# by philg@mit.edu on July 18, 1999
#
# entry form to let user edit the HTML text of a recommendation
# 

set_the_usual_form_variables

# recommendation_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select r.*, p.product_name
from ec_product_recommendations r, ec_products p
where recommendation_id=$recommendation_id
and r.product_id=p.product_id"]
set_variables_after_query

ns_db releasehandle $db 

ns_return 200 text/html "[ad_admin_header "Edit Product Recommendation Text"]

<h2>Edit Recommendation Text</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "recommendations.tcl" "Recommendations"] [list "recommendation.tcl?[export_url_vars recommendation_id]" "One"] "Edit Recommendation"]

<hr>

Edit text for the recommendation of $product_name:

<blockquote>
<form method=GET action=\"recommendation-text-edit-2.tcl\">
[export_form_vars recommendation_id]
<textarea name=recommendation_text rows=10 cols=70 wrap=soft>
[ns_quotehtml $recommendation_text]
</textarea>
<p>
<center>
<input type=submit value=\"Update\">
</form>
</center>
</blockquote>

[ad_admin_footer]
"
