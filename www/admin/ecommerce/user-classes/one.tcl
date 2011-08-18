# $Id: one.tcl,v 3.0 2000/02/06 03:22:07 ron Exp $
set_the_usual_form_variables

# user_class_id, user_class_name

ReturnHeaders

ns_write "[ad_admin_header "$user_class_name"]

<h2>$user_class_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "User Classes"] "One Class"]

<hr>

<ul>
<form method=post action=edit.tcl>
[export_form_vars user_class_id]
<li>Change user class name to: <input type=text name=user_class_name size=30 value=\"[philg_quote_double_quotes $user_class_name]\">
<input type=submit value=\"Change\">
</form>

<li><a href=\"members.tcl?[export_url_vars user_class_id]\">View all members of this user class</a>

<p>

<li><a href=\"delete.tcl?[export_url_vars user_class_id user_class_name]\">Delete this user class</a>

<p>
"

# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name "$user_class_name"
set audit_id $user_class_id
set audit_id_column "user_class_id"
set return_url "[ns_conn url]?[export_url_vars user_class_id user_class_name]"
set audit_tables [list ec_user_classes_audit]
set main_tables [list ec_user_classes]

ns_write "<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>

<p>

<li>Add a member to this user class.  Search for a member to add<br>

<form method=post action=member-add.tcl>
[export_form_vars user_class_id user_class_name]
By last name: <input type=text name=last_name size=30>
<input type=submit value=\"Search\">
</form>

<form method=post action=member-add.tcl>
[export_form_vars user_class_id user_class_name]
By email address: <input type=text name=email size=30>
<input type=submit value=\"Search\">
</form>

</ul>

[ad_admin_footer]
"
