# $Id: recommendation-delete.tcl,v 3.0 2000/02/06 03:20:42 ron Exp $
# recommendation-delete.tcl
#
# by philg@mit.edu on July 18, 1999
#
# confirmation page, takes no action
# 

set_the_usual_form_variables

# recommendation_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select r.*, p.product_name
from ec_product_recommendations r, ec_products p
where recommendation_id=$recommendation_id
and r.product_id=p.product_id"]
set_variables_after_query

if { ![empty_string_p $user_class_id] } {
    set user_class_description "to [database_to_tcl_string $db "select user_class_name from ec_user_classes where user_class_id=$user_class_id"]"
} else {
    set user_class_description "to all users"
}

ns_db releasehandle $db 

ns_return 200 text/html "[ad_admin_header "Really Delete Product Recommendation?"]

<h2>Confirm</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "recommendations.tcl" "Recommendations"] [list "recommendation.tcl?[export_url_vars recommendation_id]" "One"] "Confirm Deletion"]

<hr>

Are you sure that you want to delete this recommendation of 
$product_name ($user_class_description)?

<center>
<form method=GET action=\"recommendation-delete-2.tcl\">
[export_form_vars recommendation_id]
<input type=submit value=\"Yes, I'm sure\">
</form>
</center>

[ad_admin_footer]
"
