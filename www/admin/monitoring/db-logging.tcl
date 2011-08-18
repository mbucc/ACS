ad_page_variables {
    {n_messages 100}
}

page_validation {
    if { $n_messages < 1 } {
	error "n_messages < 1"
    }
}

set db [ns_db gethandle]

set time_format "DD/Mon/YYYY:HH24:MI:DD"

set order_by_clause "order by creation_date asc"

set selection [ns_db select $db "select
 to_char(creation_date, '$time_format') as timestamp, severity, message
from ad_db_log_messages
$order_by_clause"]

set i 0
while { [ns_db getrow $db $selection] } {

    incr i

    if { $i == $n_messages } {
	ns_db flush $db
	break
    }

    set_variables_after_query

    append log_messages "\[$timestamp\] $severity: $message\n"
}

ad_return_top_of_page "[ad_admin_header "Database Logging"]

<h2>Database Logging</h2>

[ad_admin_context_bar {"" "Monitoring"} "Database Logging"]

<hr>

<form action=db-logging.tcl method=get>

Last
<input type=text name=n_messages value=$n_messages size=3 maxlength=3>
Messages:

</form>

<blockquote><pre>
$log_messages
</pre></blockquote>

[ad_admin_footer]
"
