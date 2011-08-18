# $Id: subcategory-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:35 carsten Exp $
set_the_usual_form_variables
# category_name, category_id, subcategory_name, subcategory_id, prev_sort_key, next_sort_key

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars category_name category_id subcategory_name subcategory_id]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# see first whether they already entered this subcategory (in case they
# pushed submit twice), in which case, just redirect to 
# category.tcl

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select subcategory_id from ec_subcategories
where subcategory_id=$subcategory_id"]

if { $selection != ""} {
    ad_returnredirect "category.tcl?[export_url_vars category_id category_name]"
    return
}

# now make sure there's no subcategory in this category with that sort key already

set n_conflicts [database_to_tcl_string $db "select count(*)
from ec_subcategories
where category_id=$category_id
and sort_key = ($prev_sort_key + $next_sort_key)/2"]
if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The $category_name page appears to be out-of-date;
    perhaps someone has changed the subcategories since you last reloaded the page.
    Please go back to <a href=\"category.tcl?[export_url_vars category_id category_name]\">the $category_name page</a>, push
    \"reload\" or \"refresh\" and try again."
    return
}

ns_db dml $db "insert into ec_subcategories
(category_id, subcategory_id, subcategory_name, sort_key, last_modified, last_modifying_user, modified_ip_address)
values
($category_id, $subcategory_id, '$QQsubcategory_name', ($prev_sort_key + $next_sort_key)/2, sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"

ad_returnredirect "category.tcl?[export_url_vars category_id category_name]"
