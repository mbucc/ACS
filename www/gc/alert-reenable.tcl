# /www/gc/alert-reenable.tcl
ad_page_contract {
    Reenables an alert.
    
    @author xxx
    @date unknown
    @cvs-id alert-reenable.tcl,v 3.3.2.7 2000/09/22 01:37:50 kevin Exp
} {
    alert_id:integer,notnull
}
    
if [catch {
    db_dml alert_reenable_dml "update classified_email_alerts set valid_p = 't' where alert_id = :alert_id"
} errmsg] {
    db_release_unused_handles
    ad_return_error "Error Re-Enabling Alert" "in <a href=index>[gc_system_name]</a>
    <p>
    Here's the error that the database logged:
    <blockquote><code>
    $errmsg
    </blockquote></code>
    "
    return
} else {
    # success
    set page_content "[gc_header "Success"]

<h2>Success!</h2>

re-enabling your email alert in <a href=index>[gc_system_name]</a>

<hr>

You can return to <a href=\"edit-alerts\">your [gc_system_name]
alerts page</a> or [ad_pvt_home_link].

[gc_footer [gc_system_owner]]"


doc_return  200 text/html $page_content

}

