# /www/gc/alert-disable.tcl
ad_page_contract {
    Disables an alert.

    @param rowid only if they have a really old email message

    @author xxx
    @date unknown
    @cvs-id alert-disable.tcl,v 3.3.6.5 2000/09/22 01:37:50 kevin Exp
} {
    alert_id:integer,optional
    rowid:optional
}

set user_id [ad_verify_and_get_user_id]

if {[info exists alert_id]} {
    # got rid of valid_number_p $alert_id check.  couldn't find valid_number_p defined anywhere.

    set condition "alert_id = :alert_id"
    set condition_url "alert_id=$alert_id"
    set var_to_bind "alert_id"
} else {
    set row_id $rowid
    set condition "rowid = :row_id"
    set condition_url "rowid=[ns_urlencode $rowid]"
    set var_to_bind "rowid"
}

if {$user_id == 0} {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/alert-disable.tcl?$condition_url]
    return
}


if [catch {

    db_dml alert_disable_dml "
    update classified_email_alerts set valid_p = 'f'
    where $condition and user_id = :user_id" -bind [ad_tcl_vars_to_ns_set $var_to_bind user_id]

} errmsg] {
    db_release_unused_handles
        
    ad_return_error "Error Disabling Alert" "Here's the error that the database logged:

<blockquote><code>
$errmsg
</blockquote></code>"
    return
} else {

    set page_content "[gc_header "Success"]

<h2>Success!</h2>

disabling your email alert in <a href=index>[gc_system_name]</a>

<hr>

You can return to <a href=\"edit-alerts\">your [gc_system_name]
alerts page</a> or [ad_pvt_home_link].

[gc_footer [gc_system_owner]]"


doc_return  200 text/html $page_content

}






