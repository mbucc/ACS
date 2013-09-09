# picklist-item-add.tcl

ad_page_contract {  
    @param picklist_name
    @param prev_sort_key
    @param next_sort_key

    @author
    @creation-date
    @cvs-id picklist-item-add.tcl,v 3.1.6.5 2001/01/12 19:55:35 khy Exp
} {
    picklist_name
    prev_sort_key
    next_sort_key
}




# error checking: make sure that there is no picklist_item with the
# same picklist_name with a sort key equal to the new sort key
# (average of prev_sort_key and next_sort_key);
# otherwise warn them that their form is not up-to-date


set n_conflicts [db_string get_count_items "select count(*)
from ec_picklist_items
where picklist_name=:picklist_name
and sort_key = (:prev_sort_key + :next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The page you came from appears to be out-of-date;
    perhaps someone has changed the picklist items since you last reloaded the page.
    Please go back to the previous page, push \"reload\" or \"refresh\" and try
    again."
    return
}



append doc_body "[ad_admin_header "Add an Item"]

<h2>Add an Item</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] [list "picklists.tcl" "Picklist Management"] "Add an Item"]

<hr>
"

set picklist_item_id [db_string get_item_id_from_seq "select ec_picklist_item_id_sequence.nextval from dual"]

append doc_body "<ul>

<form method=post action=picklist-item-add-2>
[export_form_vars prev_sort_key next_sort_key picklist_name]
[export_form_vars -sign picklist_item_id]
Name: <input type=text name=picklist_item size=30>
<input type=submit value=\"Add\">
</form>

</ul>

[ad_admin_footer]
"


doc_return  200 text/html $doc_body