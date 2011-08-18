# $Id: category-toggle.tcl,v 3.0.4.1 2000/04/28 15:09:11 carsten Exp $
set_form_variables

# category_id

set db [ns_db gethandle]

ns_db dml $db "update n_to_n_primary_categories set
active_p = logical_negation(active_p) where category_id = $category_id"

ad_returnredirect "index.tcl"

