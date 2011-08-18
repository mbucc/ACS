# $Id: recommendation-add-4.tcl,v 3.0.4.1 2000/04/28 15:08:53 carsten Exp $
set_the_usual_form_variables

# product_id product_name user_class_id recommendation_text recommendation_id categorization

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# we only want to insert this into the last level of the categorization
set category_id ""
set subcategory_id ""
set subsubcategory_id ""
if { [llength $categorization] == 1 } {
    set category_id [lindex $categorization 0]
} elseif { [llength $categorization] == 2 } {
    set subcategory_id [lindex $categorization 1]
} elseif { [llength $categorization] == 3 } {
    set subsubcategory_id [lindex $categorization 2]
}

set db [ns_db gethandle]

# see if recommendation is already in the database, in which case they
# pushed submit twice, so just redirect

set n_occurrences [database_to_tcl_string $db "select count(*) from ec_product_recommendations where recommendation_id=$recommendation_id"]

if { $n_occurrences > 0 } {
    ad_returnredirect "recommendations.tcl"
    return
}

ns_db dml $db "insert into ec_product_recommendations
(recommendation_id, product_id, user_class_id, recommendation_text, active_p, category_id, subcategory_id, subsubcategory_id, 
last_modified, last_modifying_user, modified_ip_address)
values
($recommendation_id, $product_id, '$user_class_id','$QQrecommendation_text', 't', '$category_id', '$subcategory_id', '$subsubcategory_id',
sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]')
"

ad_returnredirect "recommendations.tcl"
