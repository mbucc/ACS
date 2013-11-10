ad_library {
    ACS-specific general utility routines.
    @author Philip Greenspun [philg@arsdigita.com]
    @date 2 April 1998
    @cvs-id defs-procs.tcl,v 1.8.2.13 2000/10/26 20:56:20 kevin Exp
}

#     The following two procs use the ACS release tag to return the
#     current version and release date.  In a development copy of acs the
#     release tag is not expanded and these procs return "development" and
#     "not released".  In a released copy the tag is expanded to something
#     of the form "acs-major-minor-release-Ryyyymmdd", and these procs
#     return e.g. "3.1.3" and "February 20, 2000".

proc ad_acs_version {} {
    set release_tag {acs-3-4-10-R20010211}
    regexp "acs-(\[0-9\]+)-(\[0-9\]+)-(\[0-9\]+)" \
	    $release_tag match major minor release

    if {[info exists major] && [info exists minor] && [info exists release]} {
	return "$major.$minor.$release"
    } else {
	return "development"
    }
}

proc ad_acs_release_date {} {
    set release_tag {acs-3-4-10-R20010211}
    regexp "R(\[0-9\]+)" $release_tag match release_date

    if {[info exists release_date]} {
	set year  [string range $release_date 0 3]
	set month [string range $release_date 4 5]
	set day   [string range $release_date 6 7]
	return [util_AnsiDatetoPrettyDate "$year-$month-$day"]
    } else {
	return "not released"
    }
}

# for setting cookies that will work on, e.g., 
# http://www.foobar.com and http://foobar.com 
# we need to push user through the cookie-chain.tcl 
# pipeline and use both host names explicitly

proc ad_need_cookie_chain_p {} {
    return [ad_parameter NeedCookieChainP]
}

proc ad_cookie_chain_first_host_name {} {
    return [ad_parameter CookieChainFirstHostName]
}

proc ad_cookie_chain_second_host_name {} {
    return [ad_parameter CookieChainSecondHostName]
}

# this is a technical person who can fix problems
proc ad_host_administrator {} {
    return [ad_parameter HostAdministrator]
}

# this is the main name of the Web service that you're offering
# on top of the Arsdigita Web Publishing System

proc ad_system_name {} {
    return [ad_parameter SystemName]
}

# This is the URL of a user's private workspace on the system, usually
# /pvt/home.tcl

proc ad_pvt_home {} {
    return "/pvt/home"
}

proc ad_pvt_home_name {} {
    return "workspace"
}

proc ad_pvt_home_link {} {
    return "<a href=\"/pvt/home\">your workspace</a>"
}

proc ad_site_home_link {} {
    if { [ad_get_user_id] != 0 } {
	return "<a href=\"/pvt/home\">[ad_system_name]</a>"
    } else {
	# we don't know who this person is
	return "<a href=\"/\">[ad_system_name]</a>"
    }
}

# person who owns the service 
# this person would be interested in user feedback, etc.

proc ad_system_owner {} {
    return [ad_parameter SystemOwner]
}

# a human-readable name of the publisher, suitable for
# legal blather

proc ad_publisher_name {} {
    return [ad_parameter PublisherName]
}

proc ad_url {} {
    # this will be called by email alerts. Do not use ns_conn location
    return [ad_parameter SystemURL]
}

proc ad_present_user {user_id name} {
    return "<a href=\"/shared/community-member?user_id=$user_id\">$name</a>"
}

proc ad_admin_present_user {user_id name} {
    return "<a href=\"/admin/users/one?user_id=$user_id\">$name</a>"
}

ad_proc ad_header {
    {-focus ""}
    page_title
    {extra_stuff_for_document_head ""} 
} {
    writes HEAD, TITLE, and BODY tags to start off pages in a consistent fashion.

    @param focus The name of an form input element to give focus to
    initially. The value supplied must be <code><i>form_name</i>.<i>input_name</i></code>
    (so you must name your form). The result is a small chunk of javascript code in the 
    <code>&lt;body&gt;</code> tag, that focuses the input field.
 } {

    if {[ad_parameter MenuOnUserPagesP pdm] == 1} {
	return [ad_header_with_extra_stuff -focus $focus $page_title [ad_pdm] [ad_pdm_spacer]]
    } else {
	return [ad_header_with_extra_stuff -focus $focus $page_title $extra_stuff_for_document_head]
    }
}

ad_proc ad_header_with_extra_stuff {
    {-focus ""}
    page_title
    {extra_stuff_for_document_head ""} 
    {pre_content_html ""}
} {
    This is the version of the ad_header that accepts extra stuff for the document head and pre-page content html
} {

    set html "<html>
<head>
$extra_stuff_for_document_head
<meta name=\"viewport\" content=\"initial-scale=1.0,width=device-width\" />
<link rel=\"stylesheet\" type=\"text/css\" href=\"[ad_parameter PathToStyleSheet {} /static/acs.css]\" />
<script type=\"text/javascript\" src=\"[ad_parameter PathToJavaScript {} /static/acs.js]\"></script>
<title>$page_title</title>
</head>
"

    set attr_list []
    array set attrs [list]

    if { ![empty_string_p $focus] } {
	set attrs(onLoad) "javascript:document.${focus}.focus()"
    }

    foreach attr [array names attrs] {
	lappend attr_list "$attr=\"$attrs($attr)\""
    }
    append html "<body [join $attr_list]>\n"

    append html $pre_content_html
    return $html
}

proc_doc ad_footer {{signatory ""} {suppress_curriculum_bar_p 0}} "writes a horizontal rule, a mailto address box (ad_system_owner if not specified as an argument), and then closes the BODY and HTML tags"  {
    global sidegraphic_displayed_p
    if [empty_string_p $signatory] {
	set signatory [ad_system_owner]
    } 
    if { [info exists sidegraphic_displayed_p] && $sidegraphic_displayed_p } {
	# we put in a BR CLEAR=RIGHT so that the signature will clear any side graphic
	# from the ad-sidegraphic.tcl package
	set extra_br "<br clear=right>"
    } else {
	set extra_br ""
    }
    if { [ad_parameter EnabledP curriculum 0] && [ad_parameter StickInFooterP curriculum 0] && !$suppress_curriculum_bar_p} {
	set curriculum_bar "<center>[curriculum_bar]</center>"
    } else {
	set curriculum_bar ""
    }
    if { [llength [info procs ds_link]] == 1 } {
	set ds_link [ds_link]
    } else {
	set ds_link ""
    }
    return "
<footer>
$extra_br
$curriculum_bar
<hr>
$ds_link
<a href=\"mailto:$signatory\"><address>$signatory</address></a>
</footer>
</body>
</html>"
}

# need special headers and footers for admin pages
# notably, we want pages signed by someone different
# (the user-visible pages are probably signed by
# webmaster@yourdomain.com; the admin pages are probably
# used by this person or persons.  If they don't like
# the way a page works, they should see a link to the
# email address of the programmer who can fix the page).

proc ad_admin_owner {} {
    return [ad_parameter AdminOwner]
}

ad_proc ad_admin_header {
    {-focus ""}
    page_title
} "" {
    if {[ad_parameter MenuOnAdminPagesP pdm] == 1} {

	return [ad_header_with_extra_stuff -focus $focus $page_title [ad_pdm "admin" 5 5] [ad_pdm_spacer "admin"]]

    } else {

	return [ad_header_with_extra_stuff -focus $focus $page_title]

    }
}

proc_doc ad_admin_footer {} "Signs pages with ad_admin_owner (usually a programmer who can fix bugs) rather than the signatory of the user pages" {
    if { [llength [info procs ds_link]] == 1 } {
	set ds_link [ds_link]
    } else {
	set ds_link ""
    }
    return "<hr>
$ds_link
<a href=\"mailto:[ad_admin_owner]\"><address>[ad_admin_owner]</address></a>
</body>
</html>"
}

proc_doc ad_return_complaint {exception_count exception_text} "Return a page complaining about the user's input (as opposed to an error in our software, for which ad_return_error is more appropriate)" {
    # there was an error in the user input 
    if { $exception_count == 1 } {
	set problem_string "a problem"
	set please_correct "it"
    } else {
	set problem_string "some problems"
	set please_correct "them"
    }
	    
    doc_return  200 text/html "[ad_header_with_extra_stuff "Problem with Your Input" "" ""]
    
<h2>Problem with Your Input</h2>

to <a href=/>[ad_system_name]</a>

<hr>

We had $problem_string processing your entry:
	
<ul> 
	
$exception_text
	
</ul>
	
Please back up using your browser, correct $please_correct, and
resubmit your entry.
	
<p>
	
Thank you.
	
[ad_footer]
"}


proc ad_return_exception_page {status title explanation} {
    doc_return $status text/html "[ad_header_with_extra_stuff $title "" ""]
<h2>$title</h2>
<hr>
$explanation
[ad_footer]"
}


proc_doc ad_return_error {title explanation} "Returns a page with the HTTP 500 (Error) code, along with the given title and explanation.  Should be used when an unexpected error is detected while processing a page." {
    ad_return_exception_page 500 $title $explanation
}

proc_doc ad_return_warning {title explanation} "Returns a page with the HTTP 200 (Success) code, along with the given title and explanation.  Should be used when an exceptional condition arises while processing a page which the user should be warned about, but which does not qualify as an error." {
    ad_return_exception_page 200 $title $explanation
}

proc_doc ad_return_forbidden {title explanation} "Returns a page with the HTTP 403 (Forbidden) code, along with the given title and explanation.  Should be used by access-control filters that determine whether a user has permission to request a particular page." {
    ad_return_exception_page 403 $title $explanation
}

proc_doc ad_return_if_another_copy_is_running {{max_simultaneous_copies 1} {call_adp_break_p 0}} {Returns a page to the user about how this server is busy if another copy of the same script is running.  Then terminates execution of the thread.  Useful for expensive pages that do sequential searches through Oracle tables, etc.  You don't want to tie up all of your Oracle handles and deny service to everyone else.  The call_adp_break_p argument is essential if you are calling this from an ADP page and want to avoid the performance hit of continuing to parse and run.} {
    # first let's figure out how many are running and queued
    set this_connection_url [ns_conn url]
    set n_matches 0
    foreach connection [ns_server active] {
	set query_connection_url [lindex $connection 4]
	if { $query_connection_url == $this_connection_url } {
	    # we got a match (we'll always get at least one
	    # since we should match ourselves)
	    incr n_matches
	}
    }
    if { $n_matches > $max_simultaneous_copies } {
	ad_return_warning "Too many copies" "This is an expensive page for our server, which is already running the same program on behalf of some other users.  Please try again at a less busy hour."
	# blow out of the caller as well
	if $call_adp_break_p {
	    # we were called from an ADP page; we have to abort processing
	    ns_adp_break
	}
	return -code return
    }
    # we're okay
    return 1
}

proc ad_record_query_string {query_string subsection n_results {user_id [db_null]}} {  

    if { $user_id == 0 } {
	set user_id [db_null]
    }

    set query_string_trunc [string range $query_string 0 300]

    db_dml query_string_record {
	insert into query_strings 
	(query_date, query_string, subsection, n_results, user_id) values
	(sysdate, :query_string_trunc, :subsection, :n_results, :user_id)
    }
}

proc ad_pretty_mailing_address_from_args {line1 line2 city state postal_code country_code} {
    set lines [list]
    if [empty_string_p $line2] {
	lappend lines $line1
    } elseif [empty_string_p $line1] {
	lappend lines $line2
    } else {
	lappend lines $line1
	lappend lines $line2
    }
    lappend lines "$city, $state $postal_code"
    if { ![empty_string_p $country_code] && $country_code != "us" } {
	lappend lines [ad_country_name_from_country_code $country_code]
    }
    return [join $lines "\n"]
}



proc_doc ad_get_user_info {} {Sets first_name, last_name, email in the environment of its caller.} {
    uplevel {
	set user_id [ad_get_user_id]
	if [catch {
	    db_1row get_user_info {
		select first_names, last_name, email from users where user_id = :user_id
	    }
	} errmsg] {
	    ad_return_error "Couldn't find user info" "Couldn't find user info."
	    return
	}
    }
}

# for pages that have optional decoration

proc_doc ad_decorate_top {simple_headline potential_decoration} "Use this for pages that might or might not have an image defined in ad.ini; if the second argument isn't the empty string, ad_decorate_top will prefix the simple headline with the decoration, wrapped in a div with class decoration." {
    if [empty_string_p $potential_decoration] {
	return "<header>$simple_headline</header>"
    } else {
	return "<header>$potential_decoration $simple_headline</header>"
    }
}

proc_doc ad_parameter {name {subsection ""} {default ""}} {Returns the value of a configuration parameter set in one of the .ini files in /web/yourdomain/parameters or in the package manager database tables.  In case of a conflict, priority is given to the value in the database.  If the parameter doesn't exist, returns the default specified as the third argument then the default value in the database (if appropriate) then the empty string if neither is specified.  Note that AOLserver reads these files when the server starts up and stores parameters in an in-memory hash table.  The plus side of this is that there is no hit to the file system and no need to memoize a call to ad_parameter.  The minus side is that you have to restart the server if you want to test a change made to the .ini file.} {

    if [nsv_exists $subsection $name] {
	set config_value [lindex [nsv_get $subsection $name] 0]
    } else {
	set server_name [ns_info server]
	append config_path "ns/server/" $server_name "/acs"
	if ![empty_string_p $subsection] {
	    append config_path "/$subsection"
	}
	set config_value [ns_config $config_path $name]
    }
    if ![empty_string_p $config_value] {
	return $config_value
    } else {
	return $default
    } 
}

proc_doc ad_parameter_section {{subsection ""}} {Returns all the vars in a parameter section as an ns_set.  Relies on undocumented AOLserver Tcl API call ns_configsection (analogous C API call is documented).  Differs from the API call in that it returns an empty ns_set if the parameter section does not exist.} {
    set server_name [ns_info server]
    append config_path "ns/server/" $server_name "/acs"
    if ![empty_string_p $subsection] {
	append config_path "/$subsection"
    }
    set what_aolserver_gave_us [ns_configsection $config_path]
    if [empty_string_p $what_aolserver_gave_us] {
	return [ns_set new "empty set for config section"]
    } else {
	return $what_aolserver_gave_us
    }
}

# returns particular parameter values as a Tcl list (i.e., it selects
# out those with a certain key)

proc ad_parameter_all_values_as_list {name {subsection ""}} {
    if [nsv_exists $subsection $name] {
	set the_values [nsv_get $subsection $name]
    } else {
	set server_name [ns_info server]
	append config_path "ns/server/" $server_name "/acs"
	if ![empty_string_p $subsection] {
	    append config_path "/$subsection"
	}
	set the_set [ns_configsection $config_path]
	if [empty_string_p $the_set] {
	    return [list]
	}
	set the_values [list]
	for {set i 0} {$i < [ns_set size $the_set]} {incr i} {
	    if { [ns_set key $the_set $i] == $name } {
		lappend the_values [ns_set value $the_set $i]
	    }
	}
    }
    return $the_values
}

ad_proc doc_return  {args} {
   
    A wrapper to be used instead of ns_return.  It calls <code>db_release_unused_handles</code> prior to calling ns_return.  This should be used instead of <code>ns_return</code> at the bottom of every user-viewable page.

} {
    db_release_unused_handles
    eval "ns_return $args"
}


ad_proc ad_returnfile {args} {
    A wrapper to be used instead of ns_returnfile.  It calls <code>db_release_unused_handles</code> prior to calling ns_returnfile.
} { 
    db_release_unused_handles
    eval "ns_returnfile $args"
}
