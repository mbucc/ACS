# $Id: category-administrator-update-2.tcl,v 3.0.4.1 2000/04/28 15:09:11 carsten Exp $
set_form_variables 

# category_id, user_id_from_search
# first_names_from_search, last_name_from_search, email_from_search

set db [ns_db gethandle]

ns_db dml $db "update n_to_n_primary_categories set primary_maintainer_id = $user_id_from_search where category_id = $category_id"

ad_returnredirect "category.tcl?[export_url_vars category_id]"