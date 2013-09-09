# view-alerts.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id view-alerts.tcl,v 3.3.2.7 2000/09/22 01:38:00 kevin Exp

    @param domain_id
} {
    domain_id:naturalnum,notnull
}

ad_maybe_redirect_for_registration
set admin_id [ad_get_user_id]

set domain [db_string gc_admin_view_alerts_domain_get "select domain
                                  from ad_domains where domain_id = :domain_id"]

if ![ad_administration_group_member "gc" $domain $admin_id] {
    ad_return_error "Unauthorized" "Unauthorized" 
    return
}

set keyword_header ""
if { [bboard_pls_blade_installed_p] == 1 } {
    set keyword_header "<th>Keywords</th>"
}

append html "[ad_header "Alerts for $domain"]

<h2>Alerts for $domain</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] [list "domain-top.tcl?domain_id=$domain_id" $domain] "Alerts"]

<hr>

<table>
<tr><th>Email<th>Action</th><th>Frequency</th>$keyword_header</tr>

"

set sql {
    select cea.*, cea.alert_id, decode(valid_p,'f','t','f') as not_valid_p,
           upper(email) as upper_email, email
    from classified_email_alerts cea, users
    where cea.user_id = users.user_id
    and domain_id = :domain_id
    order by not_valid_p, upper_email
}

set seen_any_enabled_p 0
set seen_disabled_p 0

db_foreach gc_admin_view_alerts_list $sql {
    
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
	set action "<a href=\"alert-toggle?[export_url_vars alert_id domain_id]\">Re-enable</a>"
    } else {
	# alert is enabled
	set seen_any_enabled_p 1
	set action "<a href=\"alert-toggle?[export_url_vars alert_id domain_id]\">Disable</a>"
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

<form method=POST action=delete-email-alerts>
[export_form_vars domain_id]

<textarea name=bad_addresses wrap=virtual rows=10 cols=60></textarea>

<P>

<input type=submit value=\"Delete Alerts\">

</form>

[ad_admin_footer]
"

db_release_unused_handles
doc_return  200 text/html $html
