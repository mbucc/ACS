# /tcl/ad-antispam.tcl

ad_library {

    utilities to block out troublesome people

    @author  philg@mit.edu
    @created April 18, 1999
    @cvs-id  ad-antispam.tcl,v 3.3.2.1 2000/09/14 07:36:27 ron Exp
}

proc_doc ad_spammer_ip_p {} "Calls ns_conn peeraddr and then tries to figure out if it matches the IP range of a known spammers." {
    set glob_patterns [ad_parameter_all_values_as_list IPglob antispam]
    set client_ip [ns_conn peeraddr]
    foreach pattern $glob_patterns {
	if [string match $pattern $client_ip] {
	    return 1
	}
    }
    # not a spammer as far as we know
    return 0
}

proc_doc ad_pretend_to_be_broken {} "Returns some headers, then sleeps, then some more stuff, then sleeps, ..." {
    ReturnHeaders
    ns_sleep 1 
    ns_write "[ad_header "Connecting to the database"]

<h2>Connecting to the database</h2>

<hr>

We're having a bit of trouble connecting to the relational database
that sits behind this service.  Trying again...

"
    ns_sleep 10
    ns_write "failed.\n\n<p>  Trying again ... "
    ns_sleep 10
    ns_write "failed.\n\n<p>  Trying once more ..."
    ns_sleep 15
    ns_write "failed.  

<p>

Please try your request again in a few minutes.  Our automated
monitors may have stabilized the server.

[ad_footer]
"
}

proc_doc ad_handle_spammers {} "Returns an appropriate page if we think it is a spammer, either pretending to be broken or explaining the ban (depending on the setting of FeignFailureP)." {
    if ![ad_spammer_ip_p] {
	# not a spammer
	return
    } else {
	if [ad_parameter FeignFailureP antispam 0] {
	    ad_pretend_to_be_broken
	} else {
	    # just tell the guy
	    ad_return_complaint 1 "<li>The computer that you're using has been blocked from [ad_system_name] (or perhaps a whole range of computers).\n"
	}
	# blow out of 2 levels (i.e., terminate the caller)
	return -code return
    } 
}

proc_doc ad_check_for_naughty_html {user_submitted_html} {

Returns a human-readable explanation if the user has used any of the
HTML tags marked as naughty in the antispam section of ad.ini, otherwise
returns an empty string.

} {
    set tag_names [string tolower [ad_parameter_all_values_as_list NaughtyTag antispam]]
    # look for a less than sign, zero or more spaces, then the tag
    if { ! [empty_string_p $tag_names]} { 
        if [regexp "< *([join $tag_names "\[ \n\t\r\f\]|"]\[ \n\t\r\f\])" [string tolower $user_submitted_html]] {
            return "<p>For security reasons we do not accept the submission of any HTML 
	    containing the following tags:</p> <code>[join $tag_names " "]</code>" 
        }
    }

    # HTML was okay as far as we know
    return ""
}


