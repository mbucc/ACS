# $Id: add.tcl,v 3.0 2000/02/06 03:21:53 ron Exp $
set_the_usual_form_variables
# user_class_name

ReturnHeaders

ns_write "[ad_admin_header "Confirm New User Class"]

<h2>Confirm New User Class</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "User Classes"] "Confirm New User Class"]

<hr>

Add the following new user class?

<blockquote>
<code>$user_class_name</code>
</blockquote>
"

set db [ns_db gethandle]
set user_class_id [database_to_tcl_string $db "select ec_user_class_id_sequence.nextval from dual"]

ns_write "<form method=post action=add-2.tcl>
[export_form_vars user_class_name user_class_id]
<center>
<input type=submit value=\"Yes\">
</center>
</form>

[ad_admin_footer]
"
