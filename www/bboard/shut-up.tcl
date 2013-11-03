# /www/bboard/shut-up.tcl
ad_page_contract {
    removes a thread alert

    @param row_id the Oracle ROWID for the row in the alerts table.  
           This is a phenomenally stupid thing to do.

    @cvs-id shut-up.tcl,v 3.4.2.6 2000/09/22 01:36:55 kevin Exp
    @change-log Lars Pind 20 July 2000
    Modified so you can only delete your own email alerts. That's useful
    because people often forward bboard spams, so if we didn't do this check, 
    the person you forward to could shut up your email alert.
} {
    row_id:integer,notnull
}

# -----------------------------------------------------------------------------

# In case a forgotten-to-be-urlencoded "+" expands to a space...
regsub " " $row_id "+" row_id

# We require that users only delete alerts for themselves

ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

if [catch {
    db_dml alert_delete {
	delete from bboard_thread_email_alerts
	where rowid = :row_id
	and user_id = :user_id
    }   
} errmsg] {

	doc_return  200 text/html "[ad_header "" "Database Update Failed"]

<h3>Database Update Failed</h3>
Error trying to update the database.  Email to [bboard_system_owner] please.  Here was the message:
<pre>

$errmsg

</pre>

<p>

Which resulted from the following SQL:

<p>

<code>
$sql
</code>

"
    return
}

doc_return 200 text/html "
[bboard_header "Database Update Complete"]

<h3>Database Update Complete</h3>

<hr>

Here was the SQL:

<p>

<code>$sql</code>


[bboard_footer]
"

