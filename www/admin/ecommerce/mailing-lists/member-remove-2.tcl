# $Id: member-remove-2.tcl,v 3.0.4.1 2000/04/28 15:08:42 carsten Exp $
set_the_usual_form_variables
# category_id, subcategory_id, subsubcategory_id, user_id

set db [ns_db gethandle]

if { ![empty_string_p $subsubcategory_id] } {
    ns_db dml $db "delete from ec_cat_mailing_lists where user_id=$user_id and subsubcategory_id=$subsubcategory_id"
} elseif { ![empty_string_p $subcategory_id] } {
    ns_db dml $db "delete from ec_cat_mailing_lists where user_id=$user_id and subcategory_id=$subcategory_id and subsubcategory_id is null"
} elseif { ![empty_string_p $category_id] } {
    ns_db dml $db "delete from ec_cat_mailing_lists where user_id=$user_id and category_id=$category_id and subcategory_id is null"
} else {
    ns_db dml $db "delete from ec_cat_mailing_lists where user_id=$user_id and category_id is null"
}

ad_returnredirect "one.tcl?[export_url_vars category_id subcategory_id subsubcategory_id]"