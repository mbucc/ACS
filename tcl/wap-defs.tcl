# /tcl/wap-defs.tcl

ad_library {

    Helper procedures for serving pages to wireless devices.

    @creation-date 24 May 2000
    @author Andrew Grumet (aegrumet@arsdigita.com)
    @cvs-id wap-defs.tcl,v 3.14.2.9 2000/09/22 01:34:06 kevin Exp
}

######
#
#  PUBLIC API
#
#####

ad_proc -public wml_templated_home_link {} {

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return This WML fragment: <blockquote><pre>
&lt;template&gt;
  &lt;do type=&quot;options&quot; name=&quot;home&quot; label=&quot;Home&quot;&gt;
    &lt;go href=&quot;$wap_home&quot;/&gt;
  &lt;/do&gt;
&lt;/template&gt;
</pre></blockquote>

} {
    return "<template>
  <do type=\"options\" name=\"home\" label=\"Home\">
    <go href=\"[wap_home]\"/>
  </do>
</template>
"
}

ad_proc -public wap_home {} {

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return The SpecialIndexPage from the wap section of the .ini file; the home URL for WAP services.

} {
    return [ad_parameter SpecialIndexPage wap /wap/i.wap]
}

ad_proc -public wap_begin_output {} {

    Returns a string containing the WAP header, XML version, and DTD.
    NOTE: This function's purpose in life has changed since v3.3.
    It used to write directly to the connection.

    @author Andrew Grumet (aegrumet@arsdigita.com)

} {
    return {<?xml version="1.0"?> 
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN" "http://www.wapforum.org/DTD/wml_1.1.xml">
    } 

}

ad_proc -public wap_begin_output_no_cache {} {

    Adds no-cache headers to the output header set and returns the
    results of wap_begin_ouput.  In practice we find that some devices
    don't obey the no cache headers, but do obey meta tags in the body
    of the document, so you'd do well to add meta tags if you want to
    be sure the page is cached.

    NOTE: This function's purpose in life has changed since v3.3.
    It used to write directly to the connection.

    @author Andrew Grumet (aegrumet@arsdigita.com)

} {
    set headers [ns_conn outputheaders]
    ns_set put $headers "Cache-Control" "no-cache, must-revalidate"
    ns_set put $headers "Pragma" "no-cache"
    return [wap_begin_output]
}

ad_proc -public wml_return {

    -no_cache:boolean
    page_wml

} {

    Writes a page to the connection, optionally writing out as HTML for
    debugging if the debug flag is set to 1.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @param page_wml The page to be written.
    @param -no_cache Do we write the page with no_cache headers?

} {

    set wml_debug_p [ad_parameter WapHTMLDebugMode wap 0]

    if !$wml_debug_p {
	if $no_cache_p {
	    set page_wml_with_preamble "[wap_begin_output_no_cache]\n$page_wml"
	} else {
	    set page_wml_with_preamble "[wap_begin_output]\n$page_wml"
	}
	doc_return  200 text/vnd.wap.wml $page_wml_with_preamble
    } else {
	doc_return  "<html><pre>"
	[ns_quotehtml $page_wml]
	</pre></html>"
    }
}

ad_proc -public wml_return_complaint {

    complaint

} {

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A complaint and a back button.
    @param complaint A complaint.

} {
    wml_return "<wml>
<template>
<do type=\"prev\" label=\"Back\">
  <prev/>
</do>
</template>
<card>
  <p>
  Problem: $complaint
  </p>
</card>
</wml>
"
}

ad_proc -public wml_simple_card {

    { -card_id {} }
    -back_link:boolean
    { -back_label Back }
    -omit_paragraph_tags:boolean
    body 

} {

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A simple WML card wrapped around $body, optionally providing a card_id and back link. 
    @param body The body of the WML card.

} {
    set retval {}
    if [empty_string_p $card_id] {
	append retval "<card>\n"
    } else {
	append retval "<card id=\"$card_id\">\n"
    }
    
    if $back_link_p {
	append retval "<do type=\"prev\" label=\"$back_label\">
  <prev/>
</do>\n"
    }

    if $omit_paragraph_tags_p {
	append retval "$body\n</card>\n"
    } else {
	append retval "<p>$body</p>\n</card>\n"
    }
}

ad_proc -public wml_select_widget {

    -onpick:boolean
    widget_name 
    options_list

} {

    Builds a WML select widget from the options_list which is of
    the form { {val1 str1} {val2 str2}...}
    <p>
    If onpick is set, the values are interpreted as URLs and
    assigned to intrinsic onpick events.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A WML select widget built from the options_list
    @param options_list a list of options of the form { {val1 str1} {val2 str2}...}
    @param widget_name A name for the select widget variable.
    @param onpick_p If true, the values are interpreted as URLs and assigned tointrinsic onpick events.


} {
    set retval {}
    if $onpick_p {
	set action onpick
    } else {
	set action value
    }

    append retval "<select name=\"$widget_name\">\n"
    foreach list_item $options_list {
	set val [lindex $list_item 0]
	set str [lindex $list_item 1]
	append retval "  <option ${action}=\"$val\">$str</option>\n"
    }
    append retval "</select>\n"
ns_log Notice "wml_select_widget: onpick? [info exists onpick_p], name=$widget_name, action = $action"
    return $retval
}

ad_proc -public wap_returnredirect {

    url
    {message "Redirecting."}

} {

    Redirection for WAP devices.  Not clear that 302 redirects are
    reliable.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @param url The target url.
    @param message A message to display while redirecting.

} {

    # Let's try regular 302 redirection.
    #ad_returnredirect $url
    #return

    # If we have problems, we'll revert to this sort of thing...
    # We must make sure that this page is NOT CACHED on the user agent.
    wml_return -no_cache "
<wml>
  <head>
    <meta http-equiv=\"Cache-Control\" content=\"max-age=0\"/>
  </head>
  <card onenterforward=\"$url\">
    <do type=\"accept\">
      <go href=\"$url\"/>
    </do>
    <p>$message</p>
  </card>
</wml>"
    return 
}

ad_proc -public wml_maybe_call {

    -parse:boolean
    phone_number

} {

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A WML link giving the user the option to call number
passed in.  If the number's structure (i.e. US 10-digit) is identified, a link is provided to the WTAI mc (Make Call) function.  If not, a link is provided to a page where the user can edit the number before making the call.  
    @param -parse Boolean indicating whether or not to try parsing
the number to identify it's structure.
    @phone_number The raw phone number string, of unknown structure.

} {
    if $parse_p {
	set result [util_parse_phone $phone_number]
    } else {
	set result [ns_set new]
	ns_set put $result number $phone_number
    }

    set the_number [ns_set get $result number]

    if [ns_set size $result] {
	set type_i [ns_set find $result type]
	if { $type_i >= 0 && [string compare [ns_set value $result $type_i] \
		UsTenDigit] == 0 } {
	    return "<a href=\"wtai://wp/mc;$the_number\">call</a>"
	} else {
	    if ![empty_string_p $the_number] {
		return "<a href=\"/wap/phone-tweak.wap?digits=$the_number\">call</a>"
	    }  
	}
    }
}
   
######
#
# REQUEST PROCESSING  
#
#####

# Treat wap files just like tcl files
rp_register_extension_handler wap rp_handle_tcl_request

######
#
#  USER-AGENT STRING MANAGEMENT
#
#####

ad_proc -private wap_import_site_url {} {

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return WapImportSiteURL from the wap section of the .ini file; this URL should be an authoritative URL for known WAP User-Agents.

} {
    return [ad_parameter WapImportSiteURL wap http://wap.colorline.no/wap-faq/useragents.php3]
}

ad_proc -private wap_import_parse_proc {} {

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return WapImportParseProc from the wap section of the .ini file; this proc should parse the contents of a page fom WapImportSiteURL and return a bunch of User-Agent strings in a tcl list.

} {
    return [ad_parameter WapImportParseProc wap wap_import_parse]
}

ad_proc -public wap_import_agent_list {} {

    Wrapper procedure for wap_get_import_agent_list.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A recent snapshot of WAP user agent strings from somewhere Out There.

} {
    return [util_memoize wap_get_import_agent_list [ad_parameter WapImportRefreshTimeout wap 120]]

}

ad_proc -public wap_get_import_agent_list {} {

    Get a list of user agents from a foreign website.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A list WAP User-Agents imported from a foreign website.

} {

    ns_log Notice "wap_get_import_agent_list: starting httpget."
    if [catch {set page_contents [ns_httpget [wap_import_site_url] 60]}] {
	return {}
    }
    ns_log Notice "wap_get_import_agent_list: httpget successful."
    
    set list_to_return [[wap_import_parse_proc]  $page_contents]

    return $list_to_return
}

ad_proc -public wap_import_parse {

    page_contents

} {

    Regexp out the WAP User-Agents from a web page and return as a tcl list.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A tcl list of WAP User-Agents
    @param page_contents A page from http://wap.colorline.no/wap-faq/useragents.php3

} {
    set page_lines [split $page_contents \n]

    foreach line $page_lines {
	if [regexp {^[^,]+} $line match] {
	    lappend agents_list $match
	}
    }
    return $agents_list
}

ad_proc -public wap_probable_html_browsers {} {

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A list of common HTML browser User-Agent strings

} {
    return [list {mozi} {ncsa} {msie} {wget} {micr} {lynx} {oper}]
}

ad_proc -public wap_user_agent_collisions {

    agent_list

} { 

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return Returns indices of User-Agents which look dangerously close to to HTML browser strings, or else an empty list.
    @param agent_list A list of User-Agent strings.


} {

    set return_list [list]

    set last_index [expr [ad_parameter WapUAStringCompareLength wap 4] - 1 ]

    for {set i 0} {$i < [llength $agent_list]} {incr i} {
	if { [lsearch [wap_probable_html_browsers] [string tolower [string range [lindex $agent_list $i] 0 $last_index]]] >= 0 } {
	    lappend return_list $i
	}
    }

    return $return_list
}

ad_proc -public wap_user_agent_p {} {

    Wrapper procedure for wap_db_user_agent_p.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return 1 if User-Agent matches a list of known WAP user agents.  0 is returned if no User-Agent is found.

} {
    # Get the user agent for the request.
    set agent [ns_set iget [ns_conn headers] User-Agent]

    if [empty_string_p $agent] {
	return 0
    }

    # Take the db hit in a memoize
    return [util_memoize "wap_db_user_agent_p {$agent}" [ad_parameter WapUserAgentDbRefresh wap 300]]
}

ad_proc -public wap_db_user_agent_p {

    agent

} {

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return 1 if $agent matches a list of known WAP user agents; 0 is returned if no User-Agent is found.
    @param agent A User-Agent header

} {

    set compare_length [ad_parameter WapUAStringCompareLength wap 4]

    ns_log Notice "wap_db_user_agent_p: hitting the db to check $agent"

    set retval [db_string wap_defs_get_count  "select count(*)
    from wap_user_agents
    where lower(substr(:agent,1,:compare_length)) like
          lower(substr(name,1,:compare_length)) || '%'
      and deletion_date is null"]

    db_release_unused_handles

    if { $retval > 0} {
	return 1
    } else {
	return 0
    }

}

ad_proc -public util_guess_doctype {} {

    Try to figure out what kind of document type to serve up.  As of
    May, 2000, this will usually be HTML, but could also be WML.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return html if the User-Agent is an HTML browser, wml if the User-Agent is a WML browser

} {

    # Assume html.  
    set guessed_type html

    if { [wap_user_agent_p] } {
	set accept [ns_set iget [ns_conn headers] Accept]
        if { [string first {text/vnd.wap.wml} $accept] >= 0 } {
            # we matched a known wap user agent + agent accepts wml.
	    set guessed_type wml
	}
	# HERE we should alert the webmaster since wap_user_agent_p
        # read positive but device didn't accept wml!
    }
    return $guessed_type
}

######
#
#  GENERAL AUTHENTICATION
#
#####

ad_proc -public wap_maybe_redirect_for_registration {} {

    Like the ad_maybe_redirect_for_registration, but redirects to a
    wap-specific login page.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    
} {
    set user_id [ad_verify_and_get_user_id]
    if !$user_id {
	set return_url_stub [ns_conn url]
	wap_returnredirect /wap/register/user-login.wap?[export_url_vars return_url_stub] "Login required."
        # Don't use ad_script_abort!
	return -code return
    }
}

ad_proc -public wap_default_email_domain {} {

    Used for appending a default domain (@somedomain.com) to user's
    email to save them some typing when logging in.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return WapDefaultEmailDomain parameter from the wap section of the .ini file
} {
    return [ad_parameter WapDefaultEmailDomain wap]
}




