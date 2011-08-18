# $Id: clear-2.tcl,v 3.0.4.1 2000/04/28 15:08:55 carsten Exp $
set db [ns_db gethandle]

# delete all tax settings
ns_db dml $db "delete from ec_sales_tax_by_state"
ad_audit_delete_row $db "" "" ec_sales_tax_by_state_audit

ad_returnredirect index.tcl