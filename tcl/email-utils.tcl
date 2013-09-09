# email-utils.tcl,v 3.2 2000/07/07 23:31:21 ron Exp
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

# The following perl script can be used to base64-encode a 
# binary file. Put in /web/yourserver/bin/encode64.pl
#
# #!/usr/local/bin/perl
# #
# # Encode a file from stdin as base64
# #
# # hqm@ai.mit.edu
# #
# # This script does the following:
# #
#
# use MIME::Base64 ();
#
# binmode(STDIN);
# binmode(STDOUT);
# while (read(STDIN, $_, 60*1024)) {
#   print MIME::Base64::encode($_);
# }

# pass in the absolute pathname  to the file you want to encode
# dst_filename is the name you want it to have in the attachment

ad_proc send_email_attachment_from_file {{-to "" -from "" -subject "" -msg "" -src_pathname "" -dst_filename ""}} {Send an email message using ns_sendmail, with a MIME base64 encoded attachment of the file src_pathname. src_pathname is an absolute pathname to a file in the local server filesystem. dst_filename is the name given to the file attachment part in the email message.} {

    set default_base64_encoder "[ad_parameter PathToACS]/bin/encode64.pl"
    set base64_encoder [ad_parameter "Base64EncoderCommand" "email" $default_base64_encoder]

    set encoded_data [exec $base64_encoder "<$src_pathname"]

    set mime_boundary "__==NAHDHDH2.28ABSDJxjhkjhsdkjhd___"

    set extra_headers [ns_set create]
    ns_set update $extra_headers "Mime-Version" "1.0"
    ns_set update $extra_headers "Content-Type" "multipart/mixed; boundary=\"$mime_boundary\""

    append body "--$mime_boundary
Content-Type: text/plain; charset=\"us-ascii\"

$msg

--$mime_boundary
Content-Type: application/octet-stream; name=\"$dst_filename\"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$dst_filename\"

"
    append body $encoded_data
    append body "\n--[set mime_boundary]--\n"
    ns_sendmail $to $from $subject $body $extra_headers

}