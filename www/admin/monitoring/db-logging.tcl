# /www/admin/monitoring/db-logging.tcl

ad_page_contract {
    # Gives a simple report from the database logging table.

    @author        michael@arsdigita.com
    @cvs-id        db-logging.tcl,v 3.3.2.5 2000/09/22 01:35:33 kevin Exp
} {
    {n_messages:integer 100}
}

# Should make this a pluggable filter to ad_page_contract
page_validation {
    if { $n_messages < 1 } {
	error "n_messages < 1"
    }
}

# These should be configurable!
#
set time_format "DD/Mon/YYYY:HH24:MI:DD"
#set order_by_clause "order by creation_date asc"

set i 0
set log_messages ""


set sql_query "select
to_char(creation_date, :time_format) as timestamp, severity, message
from ad_db_log_messages
order by creation_date asc"

db_foreach mon_log_messages $sql_query {
    incr i
    if { $i == $n_messages } {
  	break
    }
    append log_messages "\[$timestamp\] $severity: $message\n"
} if_no_rows {
    set log_messages "No messages."
}




doc_return  200 text/html "[ad_admin_header "Database Logging"]

<h2>Database Logging</h2>

[ad_admin_context_bar {"" "Monitoring"} "Database Logging"]

<hr>

<form action=db-logging method=get>

Last
<input type=text name=n_messages value=$n_messages size=3 maxlength=3>
Messages:

</form>

<blockquote><pre>
$log_messages
</pre></blockquote>

[ad_admin_footer]
"
