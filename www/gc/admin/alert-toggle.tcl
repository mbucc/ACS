# $Id: alert-toggle.tcl,v 3.1.2.1 2000/04/28 15:10:33 carsten Exp $
set_form_variables

# alert_id, domain_id

set db [ns_db gethandle]

if [catch {ns_db dml $db "update classified_email_alerts set valid_p = logical_negation(valid_p) where alert_id = $alert_id"} errmsg] {
    ad_return_error "Error Editing Alert" "Here's what the database produced:

<blockquote><code>
$errmsg
</blockquote></code>
"
return
}

ad_returnredirect "view-alerts.tcl?[export_url_vars domain_id]"
