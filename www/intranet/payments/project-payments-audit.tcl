# $Id: project-payments-audit.tcl,v 3.1.4.1 2000/03/17 08:23:09 mbryzek Exp $
# File: /www/intranet/payments/project-payments-audit.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Shows audit trail for a project
#

set_form_variables 0

# group_id

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set project_name [database_to_tcl_string $db "select 
group_name from user_groups
where group_id = $group_id"]

set page_title "Payments audit for $project_name"
set context_bar "[ad_context_bar [list "/" Home] [list "index.tcl" "Intranet"] [list "projects.tcl" "Projects"] [list "project-info.tcl?[export_url_vars group_id]"  $project_name] [list "project-payments.tcl?[export_url_vars group_id]" "Payments"] "Audit"]"

ns_return 200 text/html "
[ad_partner_header]

[ad_audit_trail $db $group_id im_project_payments_audit im_project_payments group_id]


[ad_partner_footer]
"
