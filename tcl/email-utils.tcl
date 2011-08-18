# $Id: email-utils.tcl,v 3.0 2000/02/06 03:13:31 ron Exp $
# Utilities to parse posted email messages

# parse an RFC 822 email message, and return an ns_set with headers 
# and body text.
#
# Message body will be returned associated with keyword "message_body"
#
# other headers:

proc parse_email_message {message} {
    set lines [split $message "\n"]
    set result [ns_set create]
    set in_body 0
    set last_header ""
    set header_value ""
    set header ""
    foreach line $lines {
	if {$line == {}} {
	    set in_body 1
	    if {$last_header != ""} {
		ns_set update $result $last_header $header_value
	    }
	} 
	if {$in_body} {
	    append msgbody "$line\n"
	} else {
	    # Parse Headers
	    # Is this a continuation of a multiline header?
	    # (i.e., a header line which starts with a whitespace?)
	    if {[regexp {^[ 	]} $line match]} {
		# append to accumulating value
		append header_value "\n" $line
	    } else {
		# Its a new header line.
		# Store the previously accumulated header if it exists
		if {$last_header != ""} { 
		    ns_set update $result $last_header $header_value
		    set header_value ""
		}
		set value ""
		regexp {^([^: 	]*): (.*)} $line match header value
		append header_value $value
		set last_header $header
	    }
	}
    }
    ns_set update $result message_body $msgbody
    return $result
}


# Changes a few things to their HTML equivalents.
proc clean_up_html { text_to_display } {
    regsub -all "\\&" $text_to_display "\\&amp;" html_text
    regsub -all "\>" $html_text "\\&gt;" html_text
    regsub -all "\<" $html_text "\\&lt;" html_text
    return $html_text
}

