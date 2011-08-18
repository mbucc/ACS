#
# /tcl/ad-partner.tcl
#
# system to manage site-wide templates with very little 
# intrustion to the programmer or the tcl environment.
# Requires programmers to manage and make changes to the
# templates (as opposed to a content management system
# where the client can do the changes)
#
# created by mbryzek 12/1/99, adapted originally from 
# guidestar.org
#
# $Id: ad-partner-defs.tcl,v 3.2.2.2 2000/04/28 15:08:09 carsten Exp $
#

util_report_library_entry

# We need to tell AOLServer to set cookies for our partners
proc_doc ad_partner_initialize {} "Registers every url_stub from ad_partner_url as a url" {

    # if for some reason, we can't get a db handle, what cookies do we still
    # need to register?
    set list_of_cookies_to_register [list]
    
    if { [catch {set db [ns_db gethandle subquery]} err_msg] } {
	ns_log Notice "ad-partner: Can't get db handle. Using list_of_cookies to register cookies"
    } else {
	set sub_selection [ns_db select $db "select distinct partner_cookie from ad_partner"]
	
	while { [ns_db getrow $db $sub_selection] } {
	    set_variables_after_subquery
	    if {[lsearch -exact $list_of_cookies_to_register $partner_cookie] == -1} {
		lappend list_of_cookies_to_register $partner_cookie
	    }
	}
	
	ns_db releasehandle $db
    }

    foreach partner_cookie $list_of_cookies_to_register {
	ns_register_proc GET /$partner_cookie/* ad_set_partner_cookie
	ns_register_proc POST /$partner_cookie/* ad_set_partner_cookie
	ns_log Notice "Registered partner cookie: $partner_cookie"
    }

}

ad_schedule_proc -once t 2 ad_partner_initialize

proc_doc ad_partner_from_cookie {} "Returns name of template or empty string from the ad_partner cookie " {
    set headers [ns_conn headers]
    set cookie [ns_set get $headers Cookie]
    if { [regexp {ad_partner=([^;]+)} $cookie {} template_name] && ![empty_string_p $template_name] && [string compare $template_name "expired"] != 0 } {
	return $template_name
    } else {
	return [ad_parameter CookieDefault partner]
    }

}

proc_doc ad_get_partner_query {{var_list partner_id} {partner ""}} "Returns the selection from the gs_partner table for the current partner and url. Selection includes all vars in var_list (default is just partner_id)" { 
    if { [empty_string_p $partner] } {
	set partner [ad_partner_from_cookie]
    }
    set url [ns_conn url]
    # The partner site would be the phrase between the first and second slash
    # Note that the first slash has been removed
    set stub "/[lindex [split $url "/"] 1]"
    set stub [string trim $stub]
    set sql_vars ""
    foreach var $var_list {
	if { ![empty_string_p $sql_vars] } { 
	    append sql_vars ", "
	}
	append sql_vars "partner.$var"
    }
    return "select $sql_vars
            from ad_partner partner, ad_partner_url url
            where partner.partner_id=url.partner_id
            and url.url_stub='[DoubleApos $stub]' 
            and partner.partner_cookie='[DoubleApos [string trim $partner]]'"

}


proc_doc ad_partner_get_stub {} "Returns the url stub for the ad_partner table. No trailing slash and final script name removed" {
    set url [ns_conn url]
    # remove the final slash and filename
    regexp {(.*)/[^/]*$} $url {} stub
    if { [info exists stub] && ![empty_string_p $stub] } {
	return $stub
    }
    return "/"
}


proc_doc ad_partner_default_divider {} {Returns the default divider we use in strings that represent lists} {
    return "\253"
}

proc_doc ad_partner_memoize_one { sql_query var } {Wrapper for ad_partner_memoize_list_from_db that lets us easily memoize a query that returns one thing} {
    return [lindex [ad_partner_memoize_list_from_db $sql_query [list $var]] 0]
}

proc_doc ad_partner_memoize_list_from_db { sql_query var_list {divider ""} {also_memoize_as ""} } {Allows you to memoize database queries without having to grab a db handle first. If the query you specified is not in the cache, this proc grabs a db handle, and memoizes a list, separated by divider inside the cache, of the results. Your calling proc can then process this list as it normally. Each var in var_list is simply appended as a single element to the list that is eventually returned.} {
    ns_share ad_partner_memoized_lists

    set str ""
    if { [empty_string_p $divider] } {
	# Users probably will never have this character (we hope)
	set divider [ad_partner_default_divider]
    }

    if { [info exists ad_partner_memoized_lists($sql_query)] } {
	set str $ad_partner_memoized_lists($sql_query)
    } else {
	set db [ns_db gethandle subquery]
	set selection [ns_db select $db $sql_query]
	while { [ns_db getrow $db $selection] } {
	    set_variables_after_query
	    foreach var $var_list {
		if { ![empty_string_p $str] } {
		    append str $divider
		}
		append str [expr $$var]
	    }
	}
	ns_db releasehandle $db
	set ad_partner_memoized_lists($sql_query) $str
    }
    if { ![empty_string_p $also_memoize_as] } {
	set ad_partner_memoized_lists($also_memoize_as) $str
    }
    return [split $str $divider]
}


proc_doc ad_partner_shorten_url_stub {stub } {Pulls off the last directory in the specified stub (e.g. /volunteer/register --> /volunteer} {
    if { [empty_string_p $stub] || [string compare $stub "/"] == 0 } {
	return ""
    }
    set stub_pieces [split $stub "/"]
    set length [llength $stub_pieces]
    set new_stub ""
    for { set i 0 } { $i < [expr $length - 1] } { incr i } {
	if { ![empty_string_p [lindex $stub_pieces $i]] } {
	    append new_stub "/[lindex $stub_pieces $i]"
	}
    }
    # ns_log Notice "Shortening $stub to $new_stub"

    # We must have started with a directory name (e.g. /volunteer) in which
    # case / is the parent
    if { [empty_string_p $new_stub] } {
	return "/"
    }
    return $new_stub
}


proc_doc ad_partner_procs { table {partner ""} } {Returns all procs from $table for the current partner. Memoizes the procs so we don't hit the db constantly for each partner} {
    if { [empty_string_p $partner] } {
	set partner [ad_partner_from_cookie]
    }
    set stub [ad_partner_get_stub]

    set original_query ""
    set query_list [list]
    # Shorten the url stub until we find a hit or run out  of url stubs!
    # This is slow, but tcl is simpler and we memoize the result anyway
    while { 1 } {
	# ns_log Notice "Looking for procs that match stub: $stub"
	set query "select procs.proc_name 
                     from ad_partner partner, ad_partner_url url, $table procs
                    where partner.partner_id=url.partner_id
                      and procs.url_id=url.url_id
                      and url.url_stub='[DoubleApos $stub]' 
                      and partner.partner_cookie='[DoubleApos [string trim $partner]]'"
	if { [empty_string_p $original_query] } {
	    set original_query $query
	}
	# ns_log Notice "Memoizing $query"
	set query_list [ad_partner_memoize_list_from_db $query [list proc_name]]
	# ns_log Notice "QUERY LIST IS $query_list"
	if { [llength $query_list] > 0 } {
	    break
	}
	set stub [ad_partner_shorten_url_stub $stub]
	if { [empty_string_p $stub] } {
	    break;
	}
    }
    
    if { [string compare $original_query $query] != 0 } {
	ad_partner_memoize_list_from_db $query [list proc_name] [ad_partner_default_divider] $original_query
    }


    # we check to be sure the current partner has some procedures 
    # registered for the requested url. If not, we use the templates
    # for the default partner
    if { [llength $query_list] == 0 } {
	set default [ad_parameter CookieDefault partner]
	if { (![empty_string_p $default]) && ([string compare $partner $default] != 0) } {
	    return [ad_partner_procs $table $default]
	}
    }
    return $query_list
}


proc_doc ad_get_partner_procs { db table } {Returns all procs from $table for the current partner. Memoizes the procs so we don't hit the db constantly for each partner} {
    return [ad_partner_procs $table]
}
	
proc_doc ad_get_footer_procs { {db ""} } {Returns a list of all the footer procs to call for the curre
nt section} {
    return [ad_partner_procs "ad_partner_footer_procs"]
}

proc_doc ad_get_header_procs { {db ""} } {Returns a list of all the header procs to call for the curre
nt section} {
    return [ad_partner_procs "ad_partner_header_procs"]
}


proc ad_partner_header { {cookie "" } } {
    set proc_list [ad_partner_procs "ad_partner_header_procs" $cookie]
    set header ""
    foreach proc_name $proc_list {
	append header [$proc_name]
    }
    return $header
}

proc ad_get_partner_header { {db ""} } {
    return [uplevel { ad_partner_header }]
}

proc ad_partner_footer { {cookie "" } } {
    set proc_list [ad_partner_procs "ad_partner_footer_procs" $cookie]
    set footer ""
    foreach proc_name $proc_list {
	append footer [$proc_name]
    }
    return $footer
}

proc ad_get_partner_footer { {db ""} } {
    return [uplevel { ad_partner_footer }]
}



proc_doc ad_partner_return_error { page_title {page_body ""} } {Like the normal ad_return_error except it uses partner headers and footers} {
    ns_return 200 text/html [ad_partner_return_template]
    return -code return
}


proc_doc ad_partner_var { var {db ""} {force 0} {cookie ""} } {Caches and returns the value of the specified var for the current partner.} {
    if { [empty_string_p $cookie] } {
	set cookie [ad_partner_from_cookie]
    }

    ns_share ad_partner_cache

    set varname "${cookie}_$var"

    if { $force || ![info exists ad_partner_cache($varname)] } {
	# ns_log Notice "GOING TO THE DATBASE FOR $cookie:$var"
	
	# var_list is a list of all the variables we want to grab from the database and
	# cache for the lifetime of the current server process
	set var_list [ad_partner_list_all_var_names]
	
	set sql "select [join $var_list ", "]
                 from ad_partner 
                 where partner_cookie='[DoubleApos $cookie]'"
	
	if { [empty_string_p $db] } {
	    set db [ns_db gethandle subquery]
	    set sub_selection [ns_db 0or1row $db $sql]
	    if { [empty_string_p $sub_selection] } {
		ns_db releasehandle $db
		return ""
	    }
	    set_variables_after_subquery
	    ns_db releasehandle $db
	} else {
	    set selection [ns_db 0or1row $db $sql]
	    if { [empty_string_p $selection] } {
		return ""
	    }
	    set_variables_after_query
	}

	foreach v $var_list {
	    set ad_partner_cache(${cookie}_$v) "[expr "$$v"]"
	}

	# Make sure we got the desired value from the database
	if { ![info exists ad_partner_cache($varname)] } {
	    ad_return_error "Cannot find $varname" "Missing or mistaken partner variable name"
	    return -code return
	}
    }
    return $ad_partner_cache($varname)
}


proc_doc ad_partner_var_or_default { var } {Returns the specified variable for the current parter, unless it's the empty string in which case it returns the variable for the cobrandsitedefault} {
    set value [ad_partner_var $var]
    if { ![empty_string_p $value] } {
	return $value
    }
    return [ad_partner_var $var "" 0 [ad_parameter CookieDefault partner]]
}


proc_doc ad_partner_default_font { {props ""} } {Returns an html font tag with the default font face and default font color filled in from the partner database. If props is nonempty, it is simply included in the font statement} {

    set face [ad_partner_var default_font_face]
    set color  [ad_partner_var default_font_color]
    return [ad_partner_format_font $face $color $props]
}



proc_doc ad_partner_title_font { {props ""} } {Returns an html font tag with the default font face and default font color filled in from the partner database. If props is nonempty, it is simply included in the font statement} {
    set face [ad_partner_var title_font_face]
    set color  [ad_partner_var title_font_color]
    return [ad_partner_format_font $face $color $props]
}


proc_doc ad_partner_format_font { face color props } {Returns a <font html tag based on the parameters passed, using only the non-empty ones} {
    set html ""
    if { ![empty_string_p $face] } {
	append html " face=\"$face\""
    }
    if { ![empty_string_p $color] } {
	append html " color=\"$color\""
    }
    if { ![empty_string_p $props] } {
	append html " $props"
    }
    if { [empty_string_p $html] } {
	return ""
    }
    return "<font$html>"
}


proc_doc ad_partner_url_with_query { { url "" } } {Returns the current url (or the one specified) with all queries correctly attached} {
    if { [empty_string_p $url] } {
	set url [ns_conn url]
    }
    set query [export_ns_set_vars url]
    if { ![empty_string_p $query] } {
	append url "?$query"
    }
    return $url
}

### We have a couple procs that set up and remove cookies for partners

proc_doc ad_set_partner_cookie { } "Sets a cookie based on the current url to create proper look-and-feel templates, redirecting to the normal guidestar page. If you specify a force_return_url, the cookie is set and the user is returned to that url." {
    set current_cookie [ad_partner_from_cookie]
    set url [ad_partner_url_with_query]
    # Remove leading slash if any
    regsub "^/" $url "" url
    # The partner site would be the phrase between the first and second slash
    set stub [lindex [split $url "/"] 0]
    # Try the greedy regsub first
    if {! [regsub "$stub/" $url "" return_url] } {
	regsub "$stub" $url "" return_url
    }
    if { [empty_string_p $return_url] } { 
	set return_url /
    }
    ad_returnredirect "/cookie-chain.tcl?cookie_name=[ns_urlencode ad_partner]&cookie_value=[ns_urlencode $stub]&expire_state=s&final_page=[ns_urlencode $return_url]"
    return -code return
}


proc_doc ad_partner_return_template {} {Adds the partner header and footer around the string page_body or page_content that is defined in the calling environment} {
    uplevel { 
	return "  
[ad_partner_header]
[value_if_exists page_body]
[value_if_exists page_content]
[ad_partner_footer]
"
    }
}


proc ad_partner_upvar { var {levels 2} } {
    incr levels
    set return_value ""
    for { set i 1 } { $i <= $levels } { incr i } {
	catch { 
	    upvar $i $var value
	    if { ![empty_string_p $value] } {
		set return_value $value
		return $return_value
	    } 
	} err_msg
    }
    return $return_value
}

proc_doc ad_partner_list_all_var_names {} {Returns a list of just the variable names that we are collecting. This is good when doing inserts/updates.} {
    set all_pairs [ad_partner_list_all_vars]
    set var_names [list]
    foreach pair $all_pairs {
	lappend var_names [lindex $pair 0]
    }
    return $var_names
}


proc_doc ad_partner_list_all_vars {} {Returns a list of pairs. Each pair is <English text> <variable name> where variable_name is one of the variables in the ad_partner table. This is great for simple text fields} {

    # we could use ad_parameter_section (defined in ad-defs.tcl)
    # but don't want to rely on it being defined already, so we get
    # the .ini section directly
    
    set server_name [ns_info server]
    set config_path ""
    append config_path "ns/server/" $server_name "/acs/partner"
    set ad_partner_vars [ns_configsection $config_path]

    ns_log Notice "/tcl/ad-partner.tcl has found [ns_set size $ad_partner_vars] variables (specified in $config_path)"

    set var_list [list]
    # now we have an ns_set of all the specs
    for {set i 0} {$i<[ns_set size $ad_partner_vars]} {incr i} {
	set key [ns_set key $ad_partner_vars $i]
	if { [string compare $key "Variable"] == 0 } {
	    set value [ns_set value $ad_partner_vars $i]
	    lappend var_list [split $value "|"]
	}
    }

    return $var_list

}
		
proc_doc ad_reset_partner_cookie { { return_url "/" } } "Resets ad_partner cookie and redirects to the specified url" {
    ad_returnredirect "/cookie-chain.tcl?cookie_name=[ns_urlencode ad_partner]&final_page=[ns_urlencode $return_url]"
    return -code return
}



proc_doc ad_partner_verify_cookie { {redirect_if_not_logged_in 0 } } {Makes sure the user's appropriate cookie is set and if not, redirects to the same page to set the cookie.  A special flag is set so we avoid an infinite loop when someone's cookies are off} {
    # ns_log Notice "ad_partner_verify_cookie: starting"
    set return_url "[ns_conn url]?c=1"
    set query [export_ns_set_vars url]
    if { ![empty_string_p $query] } {
	append return_url "&$query"
    }
    set user_id [ad_get_user_id]
    # ns_log Notice "USER ID: $user_id"
    if { $user_id == 0 } {
	# We wouldn't know how to set the cookie without a user id!
	if { $redirect_if_not_logged_in } {
	    ad_returnredirect /register/index.tcl?[export_url_vars return_url]
	    return -code return
	} else {
	    return
	}
    }
    set partner_cookie [ad_partner_from_cookie]
    # ns_log NOTICE "COOKIE: $partner_cookie"
    if { [empty_string_p $partner_cookie] || \
	    [string compare $partner_cookie [ad_parameter CookieDefault partner]] == 0 \
	    || [string compare $partner_cookie "expired"] == 0 } {
	set form_setid [ns_getform]
	if { [empty_string_p $form_setid] } {
	    set c 0 
	} else {
	    set c [ns_set get $form_setid c]
	}
	if { $c == 1 } {
	    ad_return_error "Your cookies are turned off" "You must turn on your cookies to use this site. Sorry for the inconvenience"
	    return -code return
	}
	set db [ns_db gethandle subquery]
	set cookie [ad_partner_cookie_from_user_id $db $user_id]
	ns_db releasehandle $db
	ad_returnredirect "/$cookie$return_url"
	return -code return
    }
}


proc_doc ad_partner_group_id_from_cookie { { cookie "" } } {Returns the group id for the specified partner cookie or for the cookie in the user's cookies. Memoizes the result.} {
    if { [empty_string_p $cookie] } {
	set cookie [ad_partner_from_cookie]
    }
    return [lindex [ad_partner_memoize_list_from_db \
	    "select group_id 
               from ad_partner 
              where partner_cookie='[DoubleApos $cookie]'" [list group_id]] 0]
}


proc_doc ad_partner_cookie_select { {sel ""} {name partner_cookie} } {Returns an html select box to select a cookie based on partner_name} {
    set var_list [ad_partner_memoize_list_from_db \
	    "select partner_cookie, partner_name
	       from ad_partner
	      order by lower(partner_name)" [list partner_cookie partner_name]]
    set inner [list ""]
    set outer [list "-- Please Select --"]
    for { set i 0 } { $i < [llength $var_list] } { set i [expr $i + 2] } {
	lappend inner [lindex $var_list $i]
	lappend outer [lindex $var_list [expr $i + 1]]
    }
    return "
<select [export_form_value name]>
[ad_generic_option_list $outer $inner $sel]
</select>
"
}



# Now we define some generic header and footer procedures
# that can be used to set-up the generic ArsDigita look and feel
proc_doc ad_partner_generic_header { {page_title ""} {extra_stuff_for_document_head ""} } {writes HEAD, TITLE, and BODY tags to start off pages in a consistent fashion} {
    if { [empty_string_p $page_title] } {
	# If we didn't get a title as an argument, look for it in the calling environment
	set page_title [ad_partner_upvar page_title]
    } 
    if { [empty_string_p $extra_stuff_for_document_head] } {
	# look for it in the calling environment
	set extra_stuff_for_document_head [ad_partner_upvar extra_stuff_for_document_head]
    } 
    set context_bar [ad_partner_upvar context_bar]
    set html "
[ad_header $page_title $extra_stuff_for_document_head]
[ad_partner_default_font]
<h2>$page_title</h2>
$context_bar
<hr>
"
    return $html
}

proc_doc ad_partner_generic_footer {} {Wrapper for ad_footer} {
    set signatory [ad_partner_upvar signatory]
    set suppress_curriculum_bar_p [ad_partner_upvar suppress_curriculum_bar_p]
    if [empty_string_p $suppress_curriculum_bar_p] {
	set suppress_curriculum_bar_p 0
    }
    return "[ad_footer $signatory $suppress_curriculum_bar_p]</font>"
}


util_report_successful_library_load