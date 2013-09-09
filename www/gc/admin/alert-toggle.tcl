# alert-toggle.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id alert-toggle.tcl,v 3.2.6.4 2000/08/01 15:52:20 psu Exp
    
    @param alert_id alert id integer
    @param domain_id domain id integer

} {
    alert_id:integer,notnull
    domain_id:integer,notnull
}

if [catch {db_dml gc_admin_alert_toggle {
    update classified_email_alerts set valid_p = logical_negation(valid_p) 
    where alert_id = :alert_id
}   } errmsg] {
    ad_return_error "Error Editing Alert" "Here's what the database produced:

    <blockquote><code>
    $errmsg
    </blockquote></code>
    "
    return
}

db_release_unused_handles

ad_returnredirect "view-alerts.tcl?[export_url_vars domain_id]"
