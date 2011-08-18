# $Id: issue-open-or-close-2.tcl,v 3.0.4.1 2000/04/28 15:08:39 carsten Exp $
set_the_usual_form_variables
# issue_id, close_p, customer_service_rep

set db [ns_db gethandle]

if { $close_p == "t" } {
    ns_db dml $db "update ec_customer_service_issues set close_date=sysdate, closed_by=$customer_service_rep where issue_id=$issue_id"
} else {
    ns_db dml $db "update ec_customer_service_issues set close_date=null where issue_id=$issue_id"
}

ad_returnredirect "issue.tcl?[export_url_vars issue_id]"