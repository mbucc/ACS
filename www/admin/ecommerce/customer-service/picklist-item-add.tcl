# $Id: picklist-item-add.tcl,v 3.0 2000/02/06 03:18:10 ron Exp $
set_the_usual_form_variables
# picklist_name, prev_sort_key, next_sort_key

# error checking: make sure that there is no picklist_item with the
# same picklist_name with a sort key equal to the new sort key
# (average of prev_sort_key and next_sort_key);
# otherwise warn them that their form is not up-to-date

set db [ns_db gethandle]
set n_conflicts [database_to_tcl_string $db "select count(*)
from ec_picklist_items
where picklist_name='$QQpicklist_name'
and sort_key = ($prev_sort_key + $next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The page you came from appears to be out-of-date;
    perhaps someone has changed the picklist items since you last reloaded the page.
    Please go back to the previous page, push \"reload\" or \"refresh\" and try
    again."
    return
}

ReturnHeaders

ns_write "[ad_admin_header "Add an Item"]

<h2>Add an Item</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] [list "picklists.tcl" "Picklist Management"] "Add an Item"]

<hr>
"

set picklist_item_id [database_to_tcl_string $db "select ec_picklist_item_id_sequence.nextval from dual"]

ns_write "<ul>

<form method=post action=picklist-item-add-2.tcl>
[export_form_vars prev_sort_key next_sort_key picklist_name picklist_item_id]
Name: <input type=text name=picklist_item size=30>
<input type=submit value=\"Add\">
</form>

</ul>

[ad_admin_footer]
"