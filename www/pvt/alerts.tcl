ad_page_contract {
    @cvs-id alerts.tcl,v 3.3.6.4 2000/09/22 01:39:09 kevin Exp
} {
}

set user_id [ad_verify_and_get_user_id]

db_1row name_get "select first_names, last_name, email, url from users where user_id=:user_id" -bind [ad_tcl_vars_to_ns_set user_id]

if { ![empty_string_p $first_names] || ![empty_string_p $last_name] } {
    set full_name "$first_names $last_name"
} else {
    set full_name "name unknown"
}


set page_content "
[ad_header "$full_name's alerts in [ad_system_name]"]

[ad_decorate_top "<h2>Email Alerts</h2>

for $full_name in [ad_system_name]
" [ad_parameter AlertPageDecoration pvt]]

<hr>


"

set wrote_something_p 0

if { [db_table_exists "bboard_email_alerts"] } {
    set sql "select bea.valid_p, bea.frequency, bea.keywords, bt.topic, bea.rowid
    from bboard_email_alerts bea, bboard_topics bt
    where bea.user_id = :user_id
    and bea.topic_id = bt.topic_id
    order by bea.frequency"

    set counter 0
    db_foreach alerts_list $sql {
	incr counter
	if { $valid_p == "f" } {
	    # alert has been disabled for some reason
	    set status "Disabled"
	    set action "<a href=\"/bboard/alert-reenable?rowid=[ns_urlencode $rowid]\">Re-enable</a>"
	} else {
	    # alert is enabled
	    set status "<font color=red>Enabled</font>"
	    set action "<a href=\"/bboard/alert-disable?rowid=[ns_urlencode $rowid]\">Disable</a>"
	}
	append existing_alert_rows "<tr><td>$status</td><td>$action</td><td>$topic</td><td>$frequency</td>"
	if { [bboard_pls_blade_installed_p] == 1 } {
	    append existing_alert_rows "<td>\"$keywords\"</td>"
	}
	append existing_alert_rows "</tr>\n"

    }

    if  { $counter > 0 } {
	set wrote_something_p 1
	set keyword_header ""
	if { [bboard_pls_blade_installed_p] == 1 } {
	    set keyword_header "<th>Keywords</th>"
	}
	append page_content "<h3>Your discussion forum alerts</h3>

	<blockquote>
	<table>
	<tr><th>Status</th><th>Action</th><th>Topic</th><th>Frequency</th>$keyword_header</tr>

	$existing_alert_rows
	</table>
	</blockquote>
	"
    }
}

if { [db_table_exists "classified_email_alerts"] } {
    set sql "
    select cea.valid_p,
           ad.domain,
           cea.alert_id,
           cea.expires,
           cea.frequency,
           cea.alert_type,
           cea.category,
           cea.keywords
    from   classified_email_alerts cea, ad_domains ad
    where  user_id = :user_id
    and    ad.domain_id = cea.domain_id
    and    sysdate <= expires
    order by expires desc"

    set alert_rows ""
    set counter 0

    db_foreach alerts_list_2 $sql {
	incr counter
	if { $valid_p == "f" } {
	    # alert has been disabled for some reason
	    set status "Off"
	    set action "<a href=\"/gc/alert-reenable?alert_id=$alert_id\">Re-enable</a>"
	} else {
	    # alert is enabled
	    set status "<font color=red>On</font>"
	    set action "<a href=\"/gc/alert-disable?rowid=$rowid\">Disable</a>"
	}
 	append alert_rows "<tr><td>$status</td><td>$action</td><td>$domain</td>
	<td><a href=\"/gc/alert-extend?rowid=$rowid\">$expires</a></td>
	<td>[gc_PrettyFrequency $frequency]</td><td>$alert_type</td>"
	if { $alert_type == "all" } {
	    append alert_rows "<td>--</td></tr>\n"
	} elseif { $alert_type == "keywords" } {
	    append alert_rows "<td>$keywords</td></tr>\n"
	} elseif { $alert_type == "category" } {
	    append alert_rows "<td>$category</td></tr>\n"
	}
    }

    if { $counter > 0 } {
	set wrote_something_p 1
	append page_content "<h3>Your [gc_system_name] alerts</h3>
	<table border><tr><th>Status</th><th>Action</th><th>Domain</th><th>Expires</th><th>Frequency</th><th>Alert Type</th><th>type-specific info</th></tr>
	$alert_rows
	</table>"
    }
}

set ticket_alerts [ticket_alert_manage $user_id] 

if {![empty_string_p $ticket_alerts]} { 
    set wrote_something_p 1
    append page_content $ticket_alerts
}

if !$wrote_something_p {
    append page_content "You currently have no email alerts registered." 
}

append page_content "

[ad_footer]
"

db_release_unused_handles
doc_return 200 text/html $page_content

