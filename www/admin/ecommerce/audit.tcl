# $Id: audit.tcl,v 3.0 2000/02/06 03:16:49 ron Exp $
# Jesse 7/17
# Displays the audit info for one id in the id_column of a table and its 
# audit history

set_the_usual_form_variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables

# where audit_tables and main_tables are tcl lists of tables to audit

set db [ns_db gethandle]

ReturnHeaders
ns_write "
[ad_admin_header "[ec_system_name] Audit Trail"]
<h2>$audit_name</h2>

[ad_admin_context_bar [list index.tcl Ecommerce] "Audit Trail"]
<hr>
"

set counter 0

foreach main_table $main_tables {
    ns_write "<h3>$main_table</h3>
    <blockquote>

    [ad_audit_trail $db $audit_id [lindex $audit_tables $counter] $main_table $audit_id_column]

    </blockquote>
    "
    incr counter
}

ns_write "[ad_admin_footer]"
