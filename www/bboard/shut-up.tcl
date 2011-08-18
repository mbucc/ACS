# $Id: shut-up.tcl,v 3.2 2000/02/16 23:41:30 bdolicki Exp $
set_form_variables

# row_id is the key

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

# In case a forgotten-to-be-urlencoded "+" expands to a space...
regsub " " $row_id "+" row_id

set sql "delete from bboard_thread_email_alerts
where rowid = '$row_id'"

with_transaction $db {
    ns_db dml $db $sql
} {
	ns_return 200 text/html "<html>
<head>
<title>Database Update Failed</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

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

    ns_return 200 text/html "<html>
<head>
<title>Database Update Complete</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h3>Database Update Complete</h3>

<hr>

Here was the SQL:

<p>

<code>$sql</code>


[bboard_footer]
"
