# $Id: alert-disable.tcl,v 3.0 2000/02/06 03:33:35 ron Exp $
set_the_usual_form_variables

# rowid

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if [catch {ns_db dml $db "update bboard_email_alerts 
set valid_p = 'f' 
where rowid = '$QQrowid'"} errmsg] {
    ad_return_error "Error Disabling Alert" "Here's what the database barfed up:

<blockquote><code>
$errmsg
</blockquote></code>
"
} else {
    # success
    ns_return 200 text/html "[bboard_header "Success"]

<h2>Success!</h2>

disabling your email alert in <a href=index.tcl>[bboard_system_name]</a>


<hr>

There isn't really a whole lot more to say...

[bboard_footer]"
}
