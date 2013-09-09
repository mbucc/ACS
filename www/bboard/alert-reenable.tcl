# /www/bboard/alert-reenable.tcl
ad_page_contract {
    reenables an alert on a bboard

    @param rowid the rowid of the alert

    @cvs-id alert-reenable.tcl,v 3.2.2.5 2000/09/22 01:36:48 kevin Exp
} {
    rowid
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

# rowid is a reserved word

set row_id $rowid

if [catch {db_dml alert_reenable "
update bboard_email_alerts 
set valid_p = 't' 
where rowid = :row_id 
AND   user_id=:user_id"} errmsg] {
    ad_return_error "Error Re-Enabling Alert" "Here's what the database barfed up:

<blockquote><code>
$errmsg
</blockquote></code>
"
} else {
    # success
    doc_return  200 text/html "[bboard_header "Success"]

<h2>Success!</h2>

re-enabling your email alert in <a href=index>[bboard_system_name]</a>


<hr>

There isn't really a whole lot more to say...


[bboard_footer]"
}
