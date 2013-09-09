# picklist-item-delete.tcl

ad_page_contract {
    @param  picklist_item_id
    @author
    @creation-date
    @cvs-id picklist-item-delete.tcl,v 3.1.6.3 2000/09/22 01:34:53 kevin Exp
} {
    picklist_item_id
}





append doc_body "[ad_admin_header "Please Confirm Deletion"]

<h2>Please Confirm Deletion</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] [list "picklists.tcl" "Picklist Management"] "Delete Item"]

<hr>
Please confirm that you wish to delete this item.

<center>
<form method=post action=picklist-item-delete-2>
[export_form_vars picklist_item_id]
<input type=submit value=\"Confirm\">
</form>
</center>

[ad_admin_footer]
"


doc_return  200 text/html $doc_body