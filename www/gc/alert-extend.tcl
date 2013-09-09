# alert-extend.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id alert-extend.tcl,v 3.3.2.6 2000/09/22 01:37:50 kevin Exp
} {
    alert_id:naturalnum
}

if { [catch { db_dml gc_alert_extend {
    update classified_email_alerts 
    set expires = sysdate + 180 
    where alert_id = :alert_id
}   } errmsg] } {
    ad_return_error "Error Extending Alert" "in <a href=index.tcl>[gc_system_name]</a>
    <p>
    Here's the error from the database:
    <blockquote><code>
    $errmsg
    </blockquote></code>
    "
}

# success
doc_return 200 text/html "
[gc_header "Success"]
<h2>Success!</h2>
extending your email alert in <a href=index.tcl>[gc_system_name]</a>
<hr>
Your alert will expire six months from now.
[gc_footer [gc_system_owner]]"

