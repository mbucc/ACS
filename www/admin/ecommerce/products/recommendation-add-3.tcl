# $Id: recommendation-add-3.tcl,v 3.0 2000/02/06 03:20:36 ron Exp $
set_the_usual_form_variables
# product_id product_name user_class_id recommendation_text categorization

# deal w/categorization for display purposes
set category_list [list]
set subcategory_list [list]
set subsubcategory_list [list]
for { set counter 0 } { $counter < [llength $categorization] } {incr counter} {
    if { $counter == 0 } {
	lappend category_list [lindex $categorization 0]
    }
    if { $counter == 1 } {
	lappend subcategory_list [lindex $categorization 1]
    }
    if { $counter == 2 } {
	lappend subsubcategory_list [lindex $categorization 2]
    }
}


set db [ns_db gethandle]
set recommendation_id [database_to_tcl_string $db "select ec_recommendation_id_sequence.nextval from dual"]    

ReturnHeaders

ns_write "[ad_admin_header "Confirm Product Recommendation"]

<h2>Confirm Product Recommendation</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "recommendations.tcl" "Recommendations"] "Add One"]

<hr>

Please confirm your product recommendation:

<blockquote>

<table cellpadding=10>
<tr>
<td>Product:</td>
<td>$product_name</td>
</tr>
<tr>
<td>Recommended For:</td>
"
if { ![empty_string_p $user_class_id] } {
    ns_write "<td>[database_to_tcl_string $db "select user_class_name from ec_user_classes where user_class_id=$user_class_id"]</td>
    "
} else {
    ns_write "<td>All Users</td>
    "
}
ns_write "</tr>
<tr>
<td>Display Recommendation In:</td>
"
if { [empty_string_p $categorization] } {
    ns_write "<td>Top Level</td>"
} else {
    ns_write "<td>[ec_category_subcategory_and_subsubcategory_display $db $category_list $subcategory_list $subsubcategory_list]</td>"
}

ns_write "</tr>
<tr>
<td>Accompanying Text<br>(HTML format):</td>
<td>$recommendation_text</td>
</tr>
</table>

</blockquote>

<form method=post action=\"recommendation-add-4.tcl\">
[export_form_vars product_id product_name user_class_id recommendation_text recommendation_id categorization]

<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"
