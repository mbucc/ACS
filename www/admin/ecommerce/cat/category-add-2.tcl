# $Id: category-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:34 carsten Exp $
set_the_usual_form_variables
# category_name, category_id, prev_sort_key, next_sort_key

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# see first whether they already entered this category (in case they
# pushed submit twice), in which case, just redirect to 
# index.tcl

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select category_id from ec_categories
where category_id=$category_id"]

if { $selection != ""} {
    ad_returnredirect "index.tcl"
    return
}

# now make sure there's no category with that sort key already
set n_conflicts [database_to_tcl_string $db "select count(*)
from ec_categories
where sort_key = ($prev_sort_key + $next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The category page appears to be out-of-date;
    perhaps someone has changed the categories since you last reloaded the page.
    Please go back to <a href=\"index.tcl\">the category page</a>, push
    \"reload\" or \"refresh\" and try again."
    return
}

ns_db dml $db "insert into ec_categories
(category_id, category_name, sort_key, last_modified, last_modifying_user, modified_ip_address)
values
($category_id, '$QQcategory_name', ($prev_sort_key + $next_sort_key)/2, sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"


ad_returnredirect "index.tcl"
