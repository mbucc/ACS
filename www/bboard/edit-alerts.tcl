# /www/bboard/edit-alerts.tcl
ad_page_contract {
    Form to edit a user's alerts

    @cvs-id edit-alerts.tcl,v 3.2.2.3 2000/09/22 01:36:50 kevin Exp
} {
}

# -----------------------------------------------------------------------------

ad_get_user_info

# now $email is set

set keyword_header ""
if { [bboard_pls_blade_installed_p] == 1 } {
    set keyword_header "<th>Keywords</th>"
}

append page_content "
[bboard_header "Edit Alerts for $email"]

<h2>Edit Alerts for $email</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] "Edit Alerts"]

<hr>

<blockquote>

<table>
<tr><th>Status<th>Action</th><th>Topic</th><th>Frequency</th>$keyword_header</tr>

"

db_foreach user_alerts "
select bea.*, rowid
from   bboard_email_alerts bea
where  user_id = :user_id
order by frequency" {

    if { $valid_p == "f" } {
	# alert has been disabled for some reason
	set status "Disabled"
	set action "<a href=\"alert-reenable?rowid=[ns_urlencode $rowid]\">Re-enable</a>"
    } else {
	# alert is enabled
	set status "Enabled"
	set action "<a href=\"alert-disable?rowid=[ns_urlencode $rowid]\">Disable</a>"
    }
    if { [bboard_pls_blade_installed_p] == 1 } {
	append page_content "<tr><td>$status<td>$action<td>$topic<td>$frequency<td>\"$keywords\"</tr>\n"
    } else {
	append page_content "<tr><td>$status<td>$action<td>$topic<td>$frequency</tr>\n"
    }

}

append page_content "

</table>
</blockquote>

[bboard_footer]
"

doc_return  200 text/html $page_content
