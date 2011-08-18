# $Id: admin-view-alerts.tcl,v 3.0 2000/02/06 03:33:31 ron Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# topic


set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return
}


# cookie checks out; user is authorized

ReturnHeaders

set keyword_header ""
if { [bboard_pls_blade_installed_p] == 1 } {
    set keyword_header "<th>Keywords</th>"
}

ns_write "<html><head>
<title>Alerts for $topic</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Alerts for $topic</h2>

in <a href=index.tcl>[bboard_system_name]</a>

<hr>

<table>
<tr><th>Email<th>Action</th><th>Frequency</th>$keyword_header</tr>

"


set selection [ns_db select $db "select bea.*, bea.rowid,
decode(valid_p,'f','t','f') as not_valid_p,
upper(email) as upper_email, email
from bboard_email_alerts bea, users
where bea.user_id = users.user_id
and topic_id = $topic_id
order by not_valid_p, upper_email"]

set seen_any_enabled_p 0
set seen_disabled_p 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $valid_p == "f" } {
	# we're into the disabled section
	if { $seen_any_enabled_p && !$seen_disabled_p } {
	    if { [bboard_pls_blade_installed_p] == 1 } {	    
		ns_write "<tr><td colspan=4 align=center>-- <b>Disabled Alerts</b> --</tr>\n"
	    } else {
		ns_write "<tr><td colspan=3 align=center>-- <b>Disabled Alerts</b> --</tr>\n"
	    }
	    set seen_disabled_p 1
	}
	set action "<a href=\"alert-reenable.tcl?rowid=$rowid\">Re-enable</a>"
    } else {
	# alert is enabled
	set seen_any_enabled_p 1
	set action "<a href=\"alert-disable.tcl?rowid=$rowid\">Disable</a>"
    }
    if { [bboard_pls_blade_installed_p] == 1 } {
	ns_write "<tr><td>$email<td>$action<td>$frequency<td>\"$keywords\"</tr>\n"
    } else {
	ns_write "<tr><td>$email<td>$action<td>$frequency</tr>\n"
    }

}

ns_write "

</table>

[bboard_footer]
"
