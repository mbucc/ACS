util_report_library_entry


proc_doc ad_removal_blurb {{subsection "" } {filetype "txt"}} "Gets the 
standard site-wide or subsection-specific removal blurb, for attaching 
to outgoing email.  txt=plain, htm=html mail, aol = aol mail" {
#    return [ad_removal_blurb_internal $subsection $filetype]
# Memoize will fail miserably if subsection is an empty string (or filetype, for that matter)
# unless we do this nasty Tcl magic. -- hqm
    return [util_memoize "ad_removal_blurb_internal {$subsection} {$filetype}"]
}
    
proc_doc ad_removal_blurb_internal {subsection filetype} "For use by ad_removal_blurb" {
    set default_blurb "------- Removal instructions ------
[ad_url]/pvt/home.tcl"


    if {[lsearch {txt aol htm} $filetype] < 0} {
	ad_return_error "error in input to ad_removal_blurb" "
	filetype should be in {txt aol htm}"
	return
    }
    if {![empty_string_p subsection]}  {
	set fd [ad_parameter RemovalBlurbStub $subsection]
	if {[empty_string_p $fd]} {
	    ns_log notice "$subsection has no RemovalBlurb parameter"
	    set fd [ad_parameter RemovalBlurbStub]
	} 
    } else {
	set fd [ad_parameter RemovalBlurbStub]
    }

    if {[empty_string_p $fd]} {
	ns_log warning "System has no RemovalBlurbStub set"
	return $default_blurb
    } 

    set blurb [subst [read_file_as_string "$fd.$filetype"]]
    if {[empty_string_p $blurb] && ![string compare $filetype "aol"]} {
	# if .aol file not defined, default to .htm
	set filetype "htm"
	set blurb [subst [read_file_as_string "$fd.$filetype"]]
    }

    if {[empty_string_p $blurb] && ![string compare $filetype "htm"]} {
	# if .htm file not defined, default to .txt
	set filetype "txt"
	set blurb [subst [read_file_as_string "$fd.$filetype"]]
    }
    if {[empty_string_p $blurb]} {
	set blurb $default_blurb
	ns_log error "RemovalBlurbStub parameter specified a bad filename"
    }
    return $blurb
}




proc spam_system_default_from_address {} {
    return [ad_parameter "SpamRobotFromAddress" "spam" "email-notification@arsdigita.com"]
}


# Really, this should make sure to generate a boundary string that
# does not appear in the content. +++
proc spam_mime_boundary {} {
    return "__NextPart_000_00A0_01BF7A3C.09877D80"
}

# return MIME content html base url
proc spam_content_base {} {
    return [ad_parameter "SpamMIMEContentBase" "spam" [ad_url]]
}

# return MIME content html location url
proc spam_content_location {} {
    return [ad_parameter "SpamMIMEContentLocation" "spam" [ad_url]]
}


# Quoted printable MIME content encoder
#
# hqm@arsdigita.com
#
# See RFC 1521 for spec of quoted printable encoding

# Build a table of encodings of chars to quoted printable
ns_share spam_quoted_printable_en spam_quoted_printable_en

for {set i 0} {$i < 256} {incr i} {
    if {(($i >= 33) && ($i <= 60)) || (($i >= 62) && ($i <= 126)) || ($i == 9) || ($i == 32)} {
	set spam_quoted_printable_en($i) [format "%c" $i]
    } else {
	set spam_quoted_printable_en($i) [format "=%X%X" [expr (($i >> 4) & 0xF)] [expr ($i & 0xF)]]
    }
}

# Encoder:
# Remove ctrl-m's
# pass chars 33 - 60, 62-126 literally, as well as space 32 and tab 9
# encode others as =XX hex
# replace LF with CRLF, (but if line ends with tab or space, encode last char as =XX)
# make soft breaks (end with "=") every 75 chars
#   
proc_doc spam_encode_quoted_printable {msg} {Returns a MIME quoted-printable RFC1521 encoded string} {
    ns_share spam_quoted_printable_en

    set result {}
    regsub -all "\r" $msg "" msg_stripped
    set length 0
    set strlen [string length $msg_stripped]
    for {set i 0} {$i < $strlen} {incr i} {
	set c [string range $msg_stripped $i $i]
	set c2 [string range $msg_stripped [expr $i + 1] [expr $i + 1]]
	scan $c "%c" x
	scan $c2 "%c" x2
	# if c is a SPACE or TAB, and next char is LF, encode C as QP
	if {(($x == 32) || ($x == 9)) && ($x2 == 10)} {
	    set qp [format "=%X%X" [expr (($x >> 4) & 0xF)] [expr ($x & 0xF)]]
	    incr length [string length $qp]
	    append result $qp
	} elseif {$x == 10} {
	    # hard line break (ASCII 10) requires conversion to MIME CRLF
	    append result "\r\n"
	    set length 0
	} else {
	    set qp $spam_quoted_printable_en($x)
	    incr length [string length $qp]
	    append result $qp
	}

	# Make soft line break at 75 characters.
	if {$length > 72} {
	    append result "=\n"
	    set length 0
	}
    }
    return $result
}


# Preserve user supplied newlines, but try to wrap text at 80 cols otherwise.
# If a token is longer than the line length threshold, then don't break it
# but put it on its own line (this is how we deal with long URL strings to 
# keep them from being mangled.

proc spam_wrap_text {input {threshold 80}} {
    regsub -all "\r" $input "" text
    set result [wrap_string $text 80]
    return $result
}


util_report_successful_library_load






























