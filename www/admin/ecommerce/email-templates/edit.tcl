# $Id: edit.tcl,v 3.0 2000/02/06 03:18:38 ron Exp $
set_the_usual_form_variables
# email_template_id


ReturnHeaders

ns_write "[ad_admin_header "Edit Email Template"]
<h2>Edit Email Template</h2>
[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Email Templates"] "Edit Template"]
<hr>
<form method=post action=\"edit-2.tcl\">
[export_form_vars email_template_id]
"

set db [ns_db gethandle]
set selection [ns_db 1row $db "select * from ec_email_templates where email_template_id=$email_template_id"]
set_variables_after_query

ns_write "<h3>For informational purposes</h3>
<blockquote>
<table noborder>
<tr><td>Title</td><td><INPUT type=text name=title size=30 value=\"[philg_quote_double_quotes $title]\"></td></tr>
<tr><td>Variables</td><td><input type=text name=variables size=30 value=\"[philg_quote_double_quotes $variables]\"> <a href=\"variables.tcl\">Note on variables</a></td></tr>
<tr><td>When Sent</td><td><textarea wrap=hard name=when_sent cols=50 rows=3>$when_sent</textarea></td></tr>
</table>
</blockquote>

<h3>Actually used when sending email</h3>

<blockquote>
<table noborder>
<tr><td>Template ID</td><td>$email_template_id</td></tr>
<tr><td>Subject Line</td><td><input type=text name=subject size=30 value=\"[philg_quote_double_quotes $subject]\"></td></tr>
<tr><td valign=top>Message</td><td><TEXTAREA wrap=hard name=message COLS=50 ROWS=15>$message</TEXTAREA></td></tr>
<tr><td valign=top>Issue Type*</td><td valign=top>[ec_issue_type_widget $db $issue_type_list]</td></tr>
</table>
</blockquote>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

* Note: A customer service issue is created whenever an email is sent. The issue is automatically closed unless the customer replies to the issue, in which case it is reopened.
"

set table_names_and_id_column [list ec_email_templates ec_email_templates_audit email_template_id]

# Set audit variables
# audit_id_column, return_url, audit_tables, main_tables
set audit_id_column "email_template_id"
set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
set audit_tables [list ec_email_templates_audit]
set main_tables [list ec_email_templates]
set audit_name "Email Template: $title"
set audit_id $email_template_id

ns_write "<p>
\[<a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>\]

[ad_admin_footer]
"
