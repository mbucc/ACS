# /admin/monitoring/startup-log.tcl

ad_page_contract {
    Displays a log (between the "AOLserver starting" and "AOLserver running" lines).

    @author Jon Salz (jsalz@mit.edu)
    @cvs-id startup-log.tcl,v 3.2.2.3 2000/09/22 01:35:34 kevin Exp
} {
    { errors_only_p 1 }
}

set dimensional_list {
    {
        errors_only_p "Show:" 1 {
	    { 1 "Errors Only" }
	    { 0 "All Events" }
	}
    }
}

set page_content "[ad_admin_header "Startup Log"]

<h2>Startup Log on [ad_system_name]</h2>

[ad_admin_context_bar [list "" "Monitoring"] "Startup Log"]
<hr>

<center><table><tr><td>[ad_dimensional $dimensional_list]</td></tr></table></center>
"

set out ""
set error_log [open [ns_info log] "r"]
set error_log_length [file size [ns_info log]]
set initial_error_log_length [nsv_get acs_properties initial_error_log_length]

if { [nsv_exists acs_properties error_log_start_offset] } {
    set start_offset [nsv_get acs_properties error_log_start_offset]
} else {
    # Go back 16K from where we first noted the log length, and look for the
    # last "AOLserver/xxx starting" line.
    set offset [expr { $initial_error_log_length - 16384 }]
    if { $offset < 0 } {
	set offset 0
    }

    set last_line $offset
    set start_offset $offset
    seek $error_log $offset start
    
    while { [gets $error_log line] >= 0 } {
	if { [regexp {AOLserver/[^ ]+ starting} $line] } {
	    set start_offset $last_line
	}
	set last_line [tell $error_log]
	if { $last_line > $initial_error_log_length } {
	    break
	}
    }

    nsv_set acs_properties error_log_start_offset $start_offset
}

seek $error_log $start_offset start

set error_p 0
while { [gets $error_log line] >= 0 } {
    if { [regexp {^\[[^\]]+\]\[[^\]]+\]\[[^\]]+\] ([^:]+)} $line "" status] } {
	if { [string equal $status "Warning"] || [string equal $status "Error"] } {
	    set error_p 1
	} else {
	    set error_p 0
	}
    }
    if { $error_p } {
	if { $errors_only_p } {
	    append out "[ns_quotehtml $line]\n"
	} else {
	    append out "<font color=red>[ns_quotehtml $line]</font>\n"
	}
    } elseif { !$errors_only_p } {
	append out "[ns_quotehtml $line]\n"
    }
    if { [regexp {AOLserver/[^ ]+ running} $line] } {
	break
    }
    if { [tell $error_log] > $error_log_length } {
	break
    }
}
close $error_log

append page_content "<pre>$out</pre>
[ad_admin_footer]
"

doc_return  200 text/html $page_content
