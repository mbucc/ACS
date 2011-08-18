# $Id: alert-disable.tcl,v 3.1.2.1 2000/04/28 15:10:30 carsten Exp $
set_the_usual_form_variables

# alert_id
# if they have a really old email message, rowid

set user_id [ad_verify_and_get_user_id]

if {[info exists alert_id]} {
    if {![valid_number_p $alert_id]} {
        ad_return_error "Error Disabling Alert" "You must enter a valid alert number."
        return
    }
    set condition "alert_id = $alert_id"
    set condition_url "alert_id=$alert_id"
} else {
    set condition "rowid = '$QQrowid'"
    set condition_url "rowid=[ns_urlencode $rowid]"
}

if {$user_id == 0} {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/alert-disable.tcl?$condition_url]
    return
}

set db [gc_db_gethandle]

if [catch {ns_db dml $db "update classified_email_alerts set valid_p = 'f' where $condition and user_id = $user_id"} errmsg] {
    ad_return_error "Error Disabling Alert" "Here's the error that the database logged:

<blockquote><code>
$errmsg
</blockquote></code>"
    return
} else {
    # success
    ns_return 200 text/html "[gc_header "Success"]

<h2>Success!</h2>

disabling your email alert in <a href=index.tcl>[gc_system_name]</a>

<hr>

You can return to <a href=\"edit-alerts.tcl\">your [gc_system_name]
alerts page</a> or [ad_pvt_home_link].

[gc_footer [gc_system_owner]]"
}
