# $Id: index.tcl,v 3.0 2000/02/06 03:18:39 ron Exp $
ReturnHeaders

set table_names_and_id_column [list ec_email_templates ec_email_templates_audit email_template_id]

ns_write "[ad_admin_header "Email Templates"]
<h2>Email Templates</h2>
[ad_admin_context_bar [list "../" "Ecommerce"] "Email Templates"]
<hr><p>
<ul>
<li><A href=\"add.tcl\">New Email Template</a>
<p>
<li><a href=\"/admin/ecommerce/audit-tables.tcl?[export_url_vars table_names_and_id_column]\">Audit All Email Templates</a>
</ul>
<p>
<b>Current Email Templates:</b>
<ul>
"

set db [ns_db gethandle]
set selection [ns_db select $db "select title, email_template_id from ec_email_templates order by title"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    ns_write "<li> <a href=\"edit.tcl?email_template_id=$email_template_id\">$title</a> \n"
}

ns_write "</ul>
[ad_admin_footer]"
