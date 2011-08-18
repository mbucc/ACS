# $Id: view-alerts.tcl,v 3.1 2000/03/11 00:45:12 curtisg Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# domain_id

set db [ns_db gethandle]

# cookie checks out; user is authorized

set keyword_header ""
if { [bboard_pls_blade_installed_p] == 1 } {
    set keyword_header "<th>Keywords</th>"
}

set domain [database_to_tcl_string $db "select domain
from ad_domains where domain_id = $domain_id"]

append html "<html><head>
<title>Alerts for $domain</title>
</head>

<body bgcolor=#ffffff text=#000000>
<h2>Alerts for $domain</h2>

in <a href=index.tcl>[ad_system_name] classifieds</a>

<hr>

<table>
<tr><th>Email<th>Action</th><th>Frequency</th>$keyword_header</tr>

"


set selection [ns_db select $db "select cea.*, cea.alert_id,
decode(valid_p,'f','t','f') as not_valid_p,
upper(email) as upper_email, email
from classified_email_alerts cea, users
where cea.user_id = users.user_id
and domain_id = $domain_id
order by not_valid_p, upper_email"]

set seen_any_enabled_p 0
set seen_disabled_p 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $valid_p == "f" } {
	# we're into the disabled section
	if { $seen_any_enabled_p && !$seen_disabled_p } {
	    if { [bboard_pls_blade_installed_p] == 1 } {	    
		append html "<tr><td colspan=4 align=center>-- <b>Disabled Alerts</b> --</tr>\n"
	    } else {
		append html "<tr><td colspan=3 align=center>-- <b>Disabled Alerts</b> --</tr>\n"
	    }
	    set seen_disabled_p 1
	}
	set action "<a href=\"alert-toggle.tcl?[export_url_vars alert_id domain_id]\">Re-enable</a>"
    } else {
	# alert is enabled
	set seen_any_enabled_p 1
	set action "<a href=\"alert-toggle.tcl?[export_url_vars alert_id domain_id]\">Disable</a>"
    }
    if { [bboard_pls_blade_installed_p] == 1 } {
	append html "<tr><td>$email<td>$action<td>$frequency<td>\"$keywords\"</tr>\n"
    } else {
	append html "<tr><td>$email<td>$action<td>$frequency</tr>\n"
    }
}

append html "

</table>
<p>
If you are seeing consistent bounces from the email notification
system then just type these addresses into the form below and the
alerts will be flushed from the database.  Place spaces between the
email addresses (but no actual carriage returns).

<form method=POST action=delete-email-alerts.tcl>
[export_form_vars domain_id]

<textarea name=bad_addresses wrap=virtual rows=10 cols=60></textarea>

<P>

<input type=submit value=\"Delete Alerts\">

</form>

[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
