# $Id: delete-email-alerts.tcl,v 3.0.4.1 2000/03/15 05:11:30 curtisg Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# bad_addresses (separated by spaces, thus a Tcl list)

set db [ns_db gethandle]

set sql "delete from classified_email_alerts where user_id in (select user_id from users where upper(email) in ('[join [string toupper $QQbad_addresses] "','"]'))"

ns_db dml $db $sql

set n_alerts_killed [ns_ora resultrows $db]

ns_return 200 text/html "<html>
<head>
<title>Alerts Deleted</title>
</head>

<body bgcolor=#ffffff text=#000000>
<h2>Alerts Deleted</h2>

in <a href=\"domain-top.tcl?[export_url_vars domain_id]\">$domain classifieds</a>
<hr>


Deleted a total of $n_alerts_killed alerts for the following email addresses:

<blockquote>
$bad_addresses
</blockquote>

<hr>
<address>philg@mit.edu</address>
</body>
</html>"
