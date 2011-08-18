# $Id: delete.tcl,v 3.0 2000/02/06 03:21:57 ron Exp $
set_the_usual_form_variables
# user_class_id

set db [ns_db gethandle]
set user_class_name [database_to_tcl_string $db "select user_class_name from ec_user_classes where user_class_id=$user_class_id"]

ReturnHeaders

ns_write "[ad_admin_header "Delete $user_class_name"]

<h2>Delete $user_class_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "User Classes"] [list "one.tcl?[export_url_vars user_class_name user_class_id]" $user_class_name] "Delete User Class"]

<hr>
Please confirm that you wish to delete this user class.  Note that this will leave any users who are currently in this class (if any) classless.

<p>

<center>
<form method=post action=delete-2.tcl>
[export_form_vars user_class_id]
<input type=submit value=\"Confirm\">
</form>
</center>

[ad_admin_footer]
"