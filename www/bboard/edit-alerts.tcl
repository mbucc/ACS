# $Id: edit-alerts.tcl,v 3.0 2000/02/06 03:33:51 ron Exp $
set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

ad_get_user_info

# now $email is set

set keyword_header ""
if { [bboard_pls_blade_installed_p] == 1 } {
    set keyword_header "<th>Keywords</th>"
}

ReturnHeaders

ns_write "[bboard_header "Edit Alerts for $email"]

<h2>Edit Alerts for $email</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] "Edit Alerts"]

<hr>

<blockquote>

<table>
<tr><th>Status<th>Action</th><th>Topic</th><th>Frequency</th>$keyword_header</tr>

"



set selection [ns_db select $db "select bea.*,rowid
from bboard_email_alerts bea
where user_id = $user_id
order by frequency"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $valid_p == "f" } {
	# alert has been disabled for some reason
	set status "Disabled"
	set action "<a href=\"alert-reenable.tcl?rowid=[ns_urlencode $rowid]\">Re-enable</a>"
    } else {
	# alert is enabled
	set status "Enabled"
	set action "<a href=\"alert-disable.tcl?rowid=[ns_urlencode $rowid]\">Disable</a>"
    }
    if { [bboard_pls_blade_installed_p] == 1 } {
	ns_write "<tr><td>$status<td>$action<td>$topic<td>$frequency<td>\"$keywords\"</tr>\n"
    } else {
	ns_write "<tr><td>$status<td>$action<td>$topic<td>$frequency</tr>\n"
    }

}

ns_write "

</table>
</blockquote>

[bboard_footer]
"
