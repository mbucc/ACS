ad_library {

    Parse the redirect section in the ad.ini file
    and register redirects accordingly
    this is documented in /doc/redirect.html.

    @creation-date January 23, 1999
    @author Philip Greenspun [philg@mit.edu]
    @cvs-id ad-redirect.tcl,v 3.4.6.1 2000/07/17 14:03:50 bquinn Exp
}

# we don't want to run this multiple times, so let's register an ns_share

ns_share -init {set ad_redirects_installed_p 0} ad_redirects_installed_p

if !$ad_redirects_installed_p {
    # we haven't done this already
    set ad_redirects_installed_p 1

    # we could use ad_parameter_section (defined in ad-defs.tcl)
    # but don't want to rely on it being defined already, so we get
    # the .ini section directly
    set server_name [ns_info server]
    append config_path "ns/server/" $server_name "/acs/redirect"
    set all_the_redirects [ns_configsection $config_path]
    ns_log Notice "/tcl/ad-redirect.tcl has found [ns_set size $all_the_redirects] redirects specified in $config_path"
    # now we have an ns_set of all the specs
    for {set i 0} {$i<[ns_set size $all_the_redirects]} {incr i} {
	set key [ns_set key $all_the_redirects $i]
	set value [ns_set value $all_the_redirects $i]
	set pair [split $value "|"]
	set from [lindex $pair 0]
	set to [lindex $pair 1]
	if { $key == "Inherit" } {
	    ns_log Notice "/tcl/ad-redirect.tcl will send anything underneath \"$from\" to \"$to\""
	    ad_register_proc GET $from ad_returnredirect $to
	} elseif { $key == "JustOne" } {
	    ns_log Notice "/tcl/ad-redirect.tcl will send \"$from\" to \"$to\""
	    ad_register_proc -noinherit t GET $from ad_returnredirect $to
	} elseif { $key == "Pattern" } {
	    ns_log Notice "/tcl/ad-redirect.tcl will reconstruct URLs that start with \"$from\" into URLs that start with \"$to\""
	    # we have to supply from and to patterns to a helper proc
	    ad_register_proc GET $from ad_redirect_pattern $value
	} elseif { $key == "PatternPost" } {
	    ns_log Notice "/tcl/ad-redirect.tcl will reconstruct forms posted to \"$from\" into URL GETs that start with \"$to\""
	    # we have to supply from and to patterns to a helper proc
	    ad_register_proc POST $from ad_redirect_pattern $value
	    ad_register_proc GET $from ad_redirect_pattern $value
	} else {
	    ns_log Error "/tcl/ad-redirect.tcl unable to do anything with $key=$value"
	}
    }
}

proc_doc ad_string_replace_once {string pattern replacement} "Replace the first occurrence of PATTERN with REPLACEMENT; return unaltered STRING if PATTERN not found" {
    set start [string first $pattern $string]
    if { $start == -1 } {
	return $string 
    } else {
	set string_front [string range $string 0 [expr $start - 1]]
	set string_end [string range $string [expr $start + [string length $pattern]] end]
	append result $string_front $replacement $string_end
	return $result
    }
}

proc_doc ad_redirect_pattern {from_and_to} "Target of redirects where a URL must be translated from starting with foo to starting with bar" {
    set pair [split $from_and_to "|"]
    set from [lindex $pair 0]
    set to [lindex $pair 1]
    set what_the_user_requested [ns_conn url]
    # Added by branimir Jan 26, 2000: URL variables also need to be included:
    if { !([ns_getform] == "") } {
	set url_vars [export_entire_form_as_url_vars]
	append what_the_user_requested ?$url_vars
    }
    ad_returnredirect [ad_string_replace_once $what_the_user_requested $from $to]
}
