# /www/gc/admin/delete-email-alerts.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id delete-email-alerts.tcl,v 3.3.2.6 2000/09/22 01:37:59 kevin Exp

    @param bad_addresses
} {
    bad_addresses
}

set bad_addresses_temp [join [string toupper $bad_addresses] "','"]

set sql "
    delete from classified_email_alerts 
    where user_id in (select user_id from users where upper(email) in (:bad_addreses))"

db_dml gc_admin_alerts_delete $sql

set n_alerts_killed [db_resultrows]

set domain [db_string gc_admin_alerts_delete_domain_get "select domain
                                  from ad_domains where domain_id = :domain_id"]

doc_return  200 text/html "<html>
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

[ad_footer]
"
