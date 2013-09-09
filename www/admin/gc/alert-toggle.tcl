# /www/admin/gc/alert-toggle.tcl
ad_page_contract {
    Allows administrator to toggle an alert (enabled/disabled).

    @param domain_id which domain
    @param alert_id which alert

    @author philg@mit.edu
    @cvs_id alert-toggle.tcl,v 3.2.6.3 2000/07/21 03:57:17 ron Exp
} {
    domain_id:integer
    alert_id:integer
}

if [catch {db_dml alert_toggle "update classified_email_alerts set valid_p = logical_negation(valid_p) where alert_id = :alert_id"} errmsg] {
    ad_return_error "Error Editing Alert" "Here's what the database produced:

<blockquote><code>
$errmsg
</blockquote></code>
"
return
}

ad_returnredirect "view-alerts.tcl?[export_url_vars domain_id]"
