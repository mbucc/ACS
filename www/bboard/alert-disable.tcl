# /www/bboard/alert-disable.tcl
ad_page_contract {
    disables an alert on a bboard

    @param rowid the rowid in the alerts table
    
    @cvs-id alert-disable.tcl,v 3.1.6.6 2000/09/22 01:36:47 kevin Exp
} {
    rowid:notnull
}

# -----------------------------------------------------------------------------

# We require that users only delete alerts for themselves

ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

# rowid is a reserved word, so we have to rename it

set row_id $rowid

if [catch {
    db_dml alert_remove {
	update bboard_email_alerts 
	set valid_p = 'f' 
	where rowid = :row_id
	and user_id = :user_id
    }
} errmsg] {
    ad_return_error "Error Disabling Alert" "Here's what the database barfed up:

<blockquote><code>
$errmsg
</blockquote></code>
"
} else {
    # success
    doc_return  200 text/html "[bboard_header "Success"]

<h2>Success!</h2>

disabling your email alert in <a href=index>[bboard_system_name]</a>


<hr>

There isn't really a whole lot more to say...

[bboard_footer]"
}
