# $Id: member-remove.tcl,v 3.0 2000/02/06 03:18:46 ron Exp $
set_the_usual_form_variables
# category_id, subcategory_id, subsubcategory_id, user_id

ReturnHeaders

ns_write "[ad_admin_header "Confirm Removal"]

<h2>Confirm Removal</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Mailing Lists"] "Confirm Removal"]

<hr>

Please confirm that you wish to remove this user from this mailing list.

<form method=post action=member-remove-2.tcl>
[export_form_vars category_id subcategory_id subsubcategory_id user_id]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"