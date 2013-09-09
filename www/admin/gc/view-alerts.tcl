# /www/admin/gc/view-alerts.tcl
ad_page_contract {
    Displays alerts for administrator.

    @param domain_id which domain

    @author philg@mit.edu
    @cvs_id view-alerts.tcl,v 3.3.2.4 2000/09/22 01:35:23 kevin Exp
} {
    domain_id:integer
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# cookie checks out; user is authorized

set keyword_header ""
if { [bboard_pls_blade_installed_p] == 1 } {
    set keyword_header "<th>Keywords</th>"
}

set domain [db_string domain "select domain from ad_domains where domain_id = :domain_id"]

set page_content "<html><head>
<title>Alerts for $domain</title>
</head>

<body bgcolor=#ffffff text=#000000>
<h2>Alerts for $domain</h2>

in <a href=index>[ad_system_name] classifieds</a>

<hr>

<table>
<tr><th>Email<th>Action</th><th>Frequency</th>$keyword_header</tr>

"

set seen_any_enabled_p 0
set seen_disabled_p 0

db_foreach alert_info {select cea.alert_id, cea.user_id, cea.expires, cea.howmuch, cea.frequency, cea.alert_type, cea.category, cea.keywords, cea.valid_p,
decode(cea.valid_p,'f','t','f') as not_valid_p,
upper(users.email) as upper_email, users.email
from classified_email_alerts cea, users
where cea.user_id = users.user_id
and cea.domain_id = :domain_id
order by not_valid_p, upper_email} {

    if { $valid_p == "f" } {
	# we're into the disabled section
	if { $seen_any_enabled_p && !$seen_disabled_p } {
	    if { [bboard_pls_blade_installed_p] == 1 } {	    
		append page_content "<tr><td colspan=4 align=center>-- <b>Disabled Alerts</b> --</tr>\n"
	    } else {
		append page_content "<tr><td colspan=3 align=center>-- <b>Disabled Alerts</b> --</tr>\n"
	    }
	    set seen_disabled_p 1
	}
	set action "<a href=\"alert-toggle?[export_url_vars alert_id domain_id]\">Re-enable</a>"
    } else {
	# alert is enabled
	set seen_any_enabled_p 1
	set action "<a href=\"alert-toggle?[export_url_vars alert_id domain_id]\">Disable</a>"
    }
    if { [bboard_pls_blade_installed_p] == 1 } {
	append page_content "<tr><td>$email<td>$action<td>$frequency<td>\"$keywords\"</tr>\n"
    } else {
	append page_content "<tr><td>$email<td>$action<td>$frequency</tr>\n"
    }
}

append page_content "

</table>
<p>
If you are seeing consistent bounces from the email notification
system then just type these addresses into the form below and the
alerts will be flushed from the database.  Place spaces between the
email addresses (but no actual carriage returns).

<form method=POST action=delete-email-alerts>
[export_form_vars domain_id domain]

<textarea name=bad_addresses wrap=virtual rows=10 cols=60></textarea>

<P>

<input type=submit value=\"Delete Alerts\">

</form>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
