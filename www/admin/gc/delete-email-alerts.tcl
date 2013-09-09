# /www/admin/gc/delete-email-alerts.tcl

ad_page_contract {
    Deletes alerts for the email addresses sent to the administrator.

    @param bad_addresses email addresses for which the administrators wants the alerts deleted (separated by spaces, thus a Tcl list)
    @param domain_id which domain
    @param domain name of the domain

    @author philg@mit.edu
    @cvs_id delete-email-alerts.tcl,v 3.3.2.4 2000/09/22 01:35:21 kevin Exp
} {
    bad_addresses
    domain_id:integer
    domain
}

# turn bad_addresses into an ns_set in order to use bind variables

set bad_addresses_set [ns_set new]

set address_counter 0
set key_list [list]

foreach address $bad_addresses {
    set key "key$address_counter"

    ns_set put $bad_addresses_set $key [string toupper $address]
    lappend key_list $key

    incr address_counter
}

set keys ":[join $key_list ", :"]"

ns_log Notice "keys is $keys"

set sql "delete from classified_email_alerts where user_id in (select user_id from users where upper(email) in ($keys))"

db_dml bad_addresses_remove $sql -bind $bad_addresses_set

set n_alerts_killed [db_resultrows]

doc_return  200 text/html "
<html>
<head>
<title>Alerts Deleted</title>
</head>

<body bgcolor=#ffffff text=#000000>
<h2>Alerts Deleted</h2>

in <a href=\"domain-top?[export_url_vars domain_id]\">$domain classifieds</a>
<hr>

Deleted a total of $n_alerts_killed alerts for the following email addresses:

<blockquote>
$bad_addresses
</blockquote>

<hr>
<address>philg@mit.edu</address>
</body>
</html>
"

