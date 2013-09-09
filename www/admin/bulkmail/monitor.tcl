#/www/admin/bulkmail/monitor.tcl
ad_page_contract {

    @author ?
    @creation-date ?
    @cvs-id monitor.tcl,v 1.3.2.6 2000/09/22 01:34:24 kevin Exp
} {
}

ns_share bulkmail_instances_mutex
ns_share bulkmail_instances
ns_share bulkmail_threads_spawned
ns_share bulkmail_threads_completed
ns_share bulkmail_db_flush_queue
ns_share bulkmail_db_flush_wait_event_mutex
ns_share bulkmail_db_flush_wait_event

set page_content "[ad_header "Bulkmail Monitor"]

<h2>Bulkmail Monitor</h2>

[ad_context_bar [list "/pvtm/" "Your Workspace"] "Bulkmail Monitor"]

<hr>
"

if { [ad_parameter BulkmailActiveP bulkmail 0] == 0 } {
    append page_content "The bulkmail system has not been enabled/initialized. Please see /doc/bulkmail.html and 
check your .ini file"
    doc_return  200 "text/html" $page_content
    return
}

ns_share bulkmail_hosts
ns_share bulkmail_failed_hosts
ns_share bulkmail_current_host

append page_content "
<p>bulkmail_hosts = { $bulkmail_hosts }
<br>bulkmail_failed_hosts =  "

set form_size [ns_set size $bulkmail_failed_hosts]
set form_counter_i 0
while {$form_counter_i<$form_size} {
    append page_content "<b>[ns_set key $bulkmail_failed_hosts $form_counter_i]</b>: [ns_quotehtml [ns_set value $bulkmail_failed_hosts $form_counter_i]], "
    incr form_counter_i
}

append page_content "

<br>bulkmail_queue_threshold = [bulkmail_queue_threshold]

<br>bulkmail_acceptable_message_lossage = [bulkmail_acceptable_message_lossage]

<br>bulkmail_acceptable_host_failures = [bulkmail_acceptable_host_failures]

<br>bulkmail_bounce_threshold = [bulkmail_bounce_threshold]

<br>bulkmail_current_host = [lindex $bulkmail_hosts $bulkmail_current_host]
<p>

<h3>Currently active mailings</h3>
<ul>
"

ns_mutex lock $bulkmail_instances_mutex
catch {
    set instances [ns_set copy $bulkmail_instances]
}
ns_mutex unlock $bulkmail_instances_mutex

set instances_size [ns_set size $instances] 
if { $instances_size == 0 } {
    append page_content "<li><em>There are no currently active mailings.</em>"
} else {
    for { set i 0 } { $i < $instances_size } { incr i } {
	set instance_stats [ns_set value $instances $i]
	set n_queued [lindex $instance_stats 0]
	set n_sent [lindex $instance_stats 1]
	set bulkmail_id [ns_set key $instances $i]

	# Go and grab the domain name and alert title from the db
	db_0or1row admin_monitor_get_bulkmail_info "select description, to_char(creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date, n_sent as db_n_sent from bulkmail_instances where bulkmail_id = $bulkmail_id"

	append page_content "<li>$bulkmail_id<a/>: $description ($n_queued queued, $n_sent sent, $db_n_sent recorded)\n"
    }
}

append page_content "</ul>"

append page_content "
<h3>System status</h3>
<ul>
<li>Total mailer threads spawned: $bulkmail_threads_spawned
<li>Total mailer threads completed: $bulkmail_threads_completed
</ul>"

append page_content "<hr>
[ad_footer]"

db_release_unused_handles
doc_return 200 "text/html" $page_content