# $Id: picklist-item-delete.tcl,v 3.0 2000/02/06 03:18:13 ron Exp $
set_the_usual_form_variables
# picklist_item_id

ReturnHeaders

ns_write "[ad_admin_header "Please Confirm Deletion"]

<h2>Please Confirm Deletion</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] [list "picklists.tcl" "Picklist Management"] "Delete Item"]

<hr>
Please confirm that you wish to delete this item.

<center>
<form method=post action=picklist-item-delete-2.tcl>
[export_form_vars picklist_item_id]
<input type=submit value=\"Confirm\">
</form>
</center>

[ad_admin_footer]
"
