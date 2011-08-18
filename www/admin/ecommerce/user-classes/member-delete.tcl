# $Id: member-delete.tcl,v 3.1 2000/03/10 01:26:41 eveander Exp $
set_the_usual_form_variables
# user_class_id, user_class_name, user_id

ReturnHeaders

ns_write "[ad_admin_header "Remove Member from $user_class_name"]

<h2>Remove Member from $user_class_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "User Classes"] [list "one.tcl?[export_url_vars user_class_id user_class_name]" $user_class_name] "Members" ] 

<hr>

Please confirm that you wish to remove this member from $user_class_name.

<center>
<form method=post action=member-delete-2.tcl>
[export_form_vars user_class_id user_class_name user_id]
<input type=submit value=\"Confirm\">
</form>
</center>

[ad_admin_footer]
"