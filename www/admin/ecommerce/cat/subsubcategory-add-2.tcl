# $Id: subsubcategory-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:36 carsten Exp $
set_the_usual_form_variables
# category_name, category_id, subcategory_name, subcategory_id, subsubcategory_name, subsubcategory_id, prev_sort_key, next_sort_key

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars category_name category_id subcategory_name subcategory_id subsubcategory_name subsubcategory_id]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}


# see first whether they already entered this subsubcategory (in case they
# pushed submit twice), in which case, just redirect to 
# subcategory.tcl

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select subsubcategory_id from ec_subsubcategories
where subsubcategory_id=$subsubcategory_id"]

if { $selection != ""} {
    ad_returnredirect "subcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]"
    return
}

# now make sure there's no subsubcategory in this subcategory with that sort key already

set n_conflicts [database_to_tcl_string $db "select count(*)
from ec_subsubcategories
where subcategory_id=$subcategory_id
and sort_key = ($prev_sort_key + $next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The $subcategory_name page appears to be out-of-date;
    perhaps someone has changed the subcategories since you last reloaded the page.
    Please go back to <a href=\"subcategory.tcl?[export_url_vars subcategory_id subcategory_name category_id category_name]\">the $subcategory_name page</a>, push
    \"reload\" or \"refresh\" and try again."
    return
}

ns_db dml $db "insert into ec_subsubcategories
(subcategory_id, subsubcategory_id, subsubcategory_name, sort_key, last_modified, last_modifying_user, modified_ip_address)
values
($subcategory_id, $subsubcategory_id, '$QQsubsubcategory_name', ($prev_sort_key + $next_sort_key)/2, sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"

ad_returnredirect "subcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]"

