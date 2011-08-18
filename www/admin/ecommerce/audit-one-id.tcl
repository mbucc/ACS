# $Id: audit-one-id.tcl,v 3.0 2000/02/06 03:16:46 ron Exp $
# Jesse 7/17
# Displays the audit info for one id in the id_column of a table and its 
# audit history

set_the_usual_form_variables
# id, id_column, audit_table_name, main_table_name

set table_names_and_id_column [list $main_table_name $audit_table_name $id_column]

set db [ns_db gethandle]

ns_return 200 text/html "
[ad_admin_header "[ec_system_name] Audit of $id_column $id"]

<h2>[ec_system_name] Audit Trail</h2>

[ad_admin_context_bar [list index.tcl Ecommerce] [list "audit-tables.tcl?[export_url_vars table_names_and_id_column]" "Audit $main_table_name"] "[ec_system_name] Audit Trail"]
<hr>

<h3>$main_table_name</h3>
<blockquote>

[ad_audit_trail $db $id $audit_table_name $main_table_name $id_column]

</blockquote>

[ad_admin_footer]
"
