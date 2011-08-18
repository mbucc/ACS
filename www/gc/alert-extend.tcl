# $Id: alert-extend.tcl,v 3.1 2000/03/10 23:58:21 curtisg Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# alert_id, or if they have an old URL, rowid

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

if [catch {ns_db dml $db "update classified_email_alerts 
set expires = sysdate + 180 
where $condition"} errmsg] {
    ad_return_error "Error Extending Alert" "in <a href=index.tcl>[gc_system_name]</a>

<p>

Here's the error from the database:

<blockquote><code>
$errmsg
</blockquote></code>

"
} else {
    # success
    ns_return 200 text/html "[gc_header "Success"]

<h2>Success!</h2>

extending your email alert in <a href=index.tcl>[gc_system_name]</a>

<hr>

Your alert will expire six months from now.


[gc_footer [gc_system_owner]]"
}
