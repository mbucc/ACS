# $Id: alert-reenable.tcl,v 3.1 2000/03/10 23:58:21 curtisg Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# rowid

set db [gc_db_gethandle]

if {[info exists alert_id]} {
    if {![valid_number_p $alert_id]} {
        ad_return_error "Error Disabling Alert" "You must enter a valid alert number."
        return
    }
    set condition "alert_id = $alert_id"
} else {
    set condition "rowid = '$QQrowid'"
}

if [catch {ns_db dml $db "update classified_email_alerts set valid_p = 't' where $condition"} errmsg] {
   ad_return_error "Error Re-Enabling Alert" "in <a href=index.tcl>[gc_system_name]</a>

<p>

Here's the error that the database logged:

<blockquote><code>
$errmsg
</blockquote></code>

"
    return
} else {
    # success
    ns_return 200 text/html "[gc_header "Success"]

<h2>Success!</h2>

re-enabling your email alert in <a href=index.tcl>[gc_system_name]</a>

<hr>

You can return to <a href=\"edit-alerts.tcl\">your [gc_system_name]
alerts page</a> or [ad_pvt_home_link].


[gc_footer [gc_system_owner]]"
}
