# $Id: recommendation-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:53 carsten Exp $
# recommendation-delete-2.tcl
#
# by philg@mit.edu on July 18, 1999
#
# actually deletes the row
# 

set_the_usual_form_variables

# recommendation_id

set db [ns_db gethandle]

ns_db dml $db "delete from ec_product_recommendations where recommendation_id=$recommendation_id"

ad_audit_delete_row $db [list $recommendation_id] [list recommendation_id] ec_product_recommend_audit

ad_returnredirect "recommendations.tcl"
