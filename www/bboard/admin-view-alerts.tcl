# /www/bboard/admin-view-alerts.tcl
ad_page_contract {
    view all alerts on a bboard topic

    @cvs-id admin-view-alerts.tcl,v 3.2.2.4 2000/11/03 00:11:17 kevin Exp
} {
    topic:notnull
}

# -----------------------------------------------------------------------------

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

# cookie checks out; user is authorized

set keyword_header ""
if { [bboard_pls_blade_installed_p] == 1 } {
    set keyword_header "<th>Keywords</th>"
}

append page_content "
[bboard_header "Alerts for $topic"]

<h2>Alerts for $topic</h2>

in <a href=index>[bboard_system_name]</a>

<hr>

<table>
<tr><th>Email<th>Action</th><th>Frequency</th>$keyword_header</tr>

"

set seen_any_enabled_p 0
set seen_disabled_p 0

db_foreach alerts "
select users.email,
       bea.frequency,
       bea.keywords,
       bea.rowid,
       decode(bea.valid_p,'f','t','f') as not_valid_p,
       upper(users.email) as upper_email
from   bboard_email_alerts bea, users
where  bea.user_id = users.user_id
and    topic_id = :topic_id
order by not_valid_p, upper_email" {

    if { $not_valid_p == "f" } {
	# we're into the disabled section
	if { $seen_any_enabled_p && !$seen_disabled_p } {
	    if { [bboard_pls_blade_installed_p] == 1 } {	    
		append page_content "<tr><td colspan=4 align=center>-- <b>Disabled Alerts</b> --</tr>\n"
	    } else {
		append page_content "<tr><td colspan=3 align=center>-- <b>Disabled Alerts</b> --</tr>\n"
	    }
	    set seen_disabled_p 1
	}
	set action "<a href=\"alert-reenable?rowid=$rowid\">Re-enable</a>"
    } else {
	# alert is enabled
	set seen_any_enabled_p 1
	set action "<a href=\"alert-disable?rowid=$rowid\">Disable</a>"
    }
    if { [bboard_pls_blade_installed_p] == 1 } {
	append page_content "<tr><td>$email<td>$action<td>$frequency<td>\"$keywords\"</tr>\n"
    } else {
	append page_content "<tr><td>$email<td>$action<td>$frequency</tr>\n"
    }

}

append page_content "

</table>

[bboard_footer]
"

doc_return  200 text/html $page_content