# /www/gc/edit-alerts.tcl

ad_page_contract {
    displays a page summarizing a user's email alerts and offering
    opportunities to disable or reenable them

    @author teadams@mit.edu
    @author philg@mit.edu
    @creation-date 1998
    @cvs-id edit-alerts.tcl,v 3.4.2.5 2000/09/22 01:37:53 kevin Exp 
}

# fixed October 30, 1999 by philg to URLencode the rowid
#
# modified March 10, 2000 by curtisg@arsdigita.com
# to use new alert_id primary key instead of rowid 

set user_id [ad_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/edit-alerts.tcl]
}

set email [db_string unused "select email from users where user_id=$user_id"]

append html "[gc_header "Edit Alerts for $email"]

<h2>Edit Alerts for $email</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] "Edit Alerts"]

<hr>

<blockquote>

"

set sql "select cea.*, ad.domain
from classified_email_alerts cea, ad_domains ad
where user_id = :user_id
and ad.domain_id = cea.domain_id
and sysdate <= expires
order by expires desc"

set alert_rows ""
set counter 0

db_foreach gc_edit_alerts_alert_list $sql {    
    incr counter
    if { $valid_p == "f" } {
	# alert has been disabled for some reason
	set status "Off"
	set action "<a href=\"alert-reenable?[export_url_vars alert_id]\">Re-enable</a>"
    } else {
	# alert is enabled
	set status "<font color=red>On</font>"
	set action "<a href=\"alert-disable?[export_url_vars alert_id]\">Disable</a>"
    }
    append alert_rows "<tr><td>$status<td>$action<td>$domain<td>
<a href=\"alert-extend?[export_url_vars alert_id]\">$expires</a>
<td>[gc_PrettyFrequency $frequency]<td>$alert_type"
    if { $alert_type == "all" } {
	append alert_rows "<td>--</tr>\n"
    } elseif { $alert_type == "keywords" } {
	append alert_rows "<td>$keywords</tr>\n"
    } elseif { $alert_type == "category" } {
	append alert_rows "<td>$category</tr>\n"
    }
}

if { $counter > 0 } {
    append html "
<table cellspacing=4><tr><th>Status</tr><th>Action</th><th>Domain<th>Expires</th><th>Frequency</th><th>Alert Type</th><th>type-specific info</tr>
$alert_rows
</table>
"
} else {
    append html "currently, the database does not have any classified alerts for you"
}

append html "

</blockquote>

<P>

<i>Note: check <a href=\"/pvt/alerts\">your site-wide alerts
page</a> for a list of alerts that you might have in other subsystems.</i>

[gc_footer [gc_system_owner]]"

doc_return  200 text/html $html
