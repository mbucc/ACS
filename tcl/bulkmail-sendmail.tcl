# bulkmail_sendmail.tcl
#
# Lots hacked from sendmail.tcl
# not useful as a general purpose mailer.

util_report_library_entry

proc bulkmail_header_exists_p {header_name headers} {
    if { [empty_string_p $headers] || ([ns_set ifind $headers $header_name] == -1) } {
	return 0
    }

    return 1
}

proc bulkmail_smtp_send {wfp string timeout} {
    if {[lindex [ns_sockselect -timeout $timeout {} $wfp {}] 1] == ""} {
	error "Timeout writing to SMTP host"
    }
    puts $wfp $string\r
    flush $wfp
}


proc bulkmail_smtp_recv {rfp check timeout} {
    while (1) {
	if {[lindex [ns_sockselect -timeout $timeout $rfp {} {}] 0] == ""} {
	    error "Timeout reading from SMTP host"
	}
	set line [gets $rfp]
	set code [string range $line 0 2]
	if ![string match $check $code] {
	    error "Expected a $check status line; got:\n$line"
	}
	if ![string match "-" [string range $line 3 3]] {
	    break;
	}
    }
}

proc bulkmail_smtp_read {rfp timeout} {
    while (1) {
	if {[lindex [ns_sockselect -timeout $timeout $rfp {} {}] 0] == ""} {
	    error "Timeout reading from SMTP host"
	}
	set line [gets $rfp]
	return $line
    }
}

proc bulkmail_smtp_open {mailhost timeout} {
    set hostname [bulkmail_smtp_hostname $mailhost]
    set port [bulkmail_smtp_port $mailhost]

    ## Open the connection
    set sock [ns_sockopen $hostname $port]
    set rfp [lindex $sock 0]
    set wfp [lindex $sock 1]

    if { [catch {
	bulkmail_smtp_recv $rfp 220 $timeout
	bulkmail_smtp_send $wfp "HELO AOLserver [ns_info hostname]" $timeout
	bulkmail_smtp_recv $rfp 250 $timeout

    } errMsg ] } {
	## Error, close and report
	close $rfp
	close $wfp
	return -code error $errMsg
    }

    return $sock
}

proc bulkmail_smtp_close {rfp wfp {timeout 60}} {
    if { [catch {
	bulkmail_smtp_send $wfp QUIT $timeout
	bulkmail_smtp_recv $rfp 221 $timeout
    } errMsg ] } {
	## Error, close and report
	close $rfp
	close $wfp
	return -code error $errMsg
    }

    ## Close the connection
    close $rfp
    close $wfp    
}

proc bulkmail_smtp_reset {rfp wfp {timeout 60}} {
    if { [catch {
	bulkmail_smtp_send $wfp RSET $timeout
	bulkmail_smtp_recv $rfp 250 $timeout
    } errMsg ] } {
	## Error, close and report
	close $rfp
	close $wfp
	return -code error $errMsg
    }

}

proc bulkmail_build_message { bulkmail_id user_id sender from to subject body {headers {}} {bcc {}}} {

    ## Takes comma-separated values in the "to" parm
    ## Multiple To and BCC addresses are handled appropriately.
    ## Original ns_sendmail functionality is preserved.

    ## Cut out carriage returns
    regsub -all "\n" $to "" to
    regsub -all "\r" $to "" to
    regsub -all "\n" $bcc "" bcc
    regsub -all "\r" $bcc "" bcc
    
    ## Split to into a proper list
    set tolist_in [split $to ","]
    set bcclist_in [split $bcc ","]

    ## Extract "from" email address
    if [regexp {.*<(.*)>} $from ig address] {
	set from $address
    }
    
    set tolist [list]
    foreach toaddr $tolist_in {
	if [regexp {.*<(.*)>} $toaddr ig address] {
	    set toaddr $address
	}
	lappend tolist "[string trim $toaddr]"
    }
    
    set bcclist [list]
    if ![string match "" $bcclist_in] {
	foreach bccaddr $bcclist_in {
	    if [regexp {.*<(.*)>} $bccaddr ig address] {
		set bccaddr $address
	    }
	    lappend bcclist "[string trim $bccaddr]"
	}
    }

    ## Put the tolist in the headers
    set rfcto [join $tolist ", "]


    set msg ""

    if [empty_string_p $headers] {
	set headers [ns_set create]
    }

    if ![bulkmail_header_exists_p "From" $headers] {
	ns_set put $headers "From" $from
    }

    if ![bulkmail_header_exists_p "To" $headers] {
	ns_set put $headers "To" $to
    }

    if ![bulkmail_header_exists_p "Subject" $headers] {
	ns_set put $headers "Subject" $subject
    }

    if ![bulkmail_header_exists_p "Date" $headers] {
	ns_set put $headers "Date" [ns_httptime [ns_time]]
    }

    ## Insert headers
    if ![string match "" $headers] {
	set size [ns_set size $headers]
	for {set i 0} {$i < $size} {incr i} {
	    append msg "[ns_set key $headers $i]: [ns_set value $headers $i]\n"
	}
    }

    
    append msg "\n$body"


    ## Terminate body with a solitary period
    foreach line [split $msg "\n"] { 
	regsub {^[.]} $line ".." quoted_line
	append data $quoted_line
	append data "\r\n"
    }
    append data .

    return [list $bulkmail_id $user_id $sender $from $tolist $bcclist $data]
}

proc bulkmail_sendmail { messages mailhost } {

    ns_share bulkmail_threads_sema
    
    set timeout [ns_config ns/parameters smtptimeout]
    if [string match "" $timeout] {
	set timeout 60
    }

    bulkmail_reset_hosts_if_needed

    if { [catch {
	set sock [bulkmail_smtp_open $mailhost $timeout]
    } errMsg ] } {
	bulkmail_record_failed_host $mailhost
	ns_sema release $bulkmail_threads_sema

	# We're going to need to try again
	ns_thread begindetached "bulkmail_sendmail {$messages} {[bulkmail_get_current_host]}"
	return
    }
    set rfp [lindex $sock 0]
    set wfp [lindex $sock 1]

    set flush_queue [list]
    set counter 0
    foreach message $messages {
	set bulkmail_id [bulkmail_message_bulkmail_id $message]
	set user_id [bulkmail_message_user_id $message]
	set sender [bulkmail_message_sender $message]
	set from [bulkmail_message_from $message]
	set tolist [bulkmail_message_tolist $message]
	set bcclist [bulkmail_message_bcclist $message]
	set body [bulkmail_message_body $message]


	_bulkmail_sendmail $rfp $wfp $timeout $tolist $bcclist $sender $body
	lappend flush_queue [list $bulkmail_id $user_id [bulkmail_ansi_current_time]]
#	bulkmail_record_sent_message $bulkmail_id $user_id [bulkmail_ansi_current_time]
	if { [llength $flush_queue] >= [bulkmail_acceptable_message_lossage] } {
	    bulkmail_record_sent_messages $flush_queue
	    set flush_queue [list]
	}

	bulkmail_smtp_reset $rfp $wfp $timeout
    }

    if { [llength $flush_queue] > 0 } {
	bulkmail_record_sent_messages $flush_queue
    }

    bulkmail_smtp_close $rfp $wfp $timeout
    ns_sema release $bulkmail_threads_sema
    bulkmail_decrement_threadcount
    ns_log Notice "Threads active: [bulkmail_current_threadcount]"
}


proc _bulkmail_sendmail {rfp wfp timeout tolist bcclist \
	sender data } {
    
    

    ## Perform the SMTP conversation
    if { [catch {
	bulkmail_smtp_send $wfp "MAIL FROM:<$sender>" $timeout
	bulkmail_smtp_recv $rfp 250 $timeout
	
	## Loop through To list via multiple RCPT TO lines
	foreach toto $tolist {
	    bulkmail_smtp_send $wfp "RCPT TO:<$toto>" $timeout
	    bulkmail_smtp_recv $rfp 250 $timeout	
	}
	
	## Loop through BCC list via multiple RCPT TO lines
	## A BCC should never, ever appear in the header.  Ever.  Not even.
	foreach bccto $bcclist {
	    bulkmail_smtp_send $wfp "RCPT TO:<$bccto>" $timeout
	    bulkmail_smtp_recv $rfp 250 $timeout
	}
	
	bulkmail_smtp_send $wfp DATA $timeout
	bulkmail_smtp_recv $rfp 354 $timeout
	bulkmail_smtp_send $wfp $data $timeout
	bulkmail_smtp_recv $rfp 250 $timeout
    } errMsg ] } {
	## Error, close and report
	close $rfp
	close $wfp
	return -code error $errMsg
    }

}

util_report_successful_library_load
