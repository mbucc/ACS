# $Id: ad-security.tcl,v 3.10.2.4 2000/04/28 15:08:12 carsten Exp $
# File:        ad-security.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        16 Feb 2000
# Description: Provides methods for authorizing and identifying ACS users
#              (both logged in and not) and tracking their sessions.


# Cookies:
#
#   ad_browser_id    := <browser_id>
#   ad_session_id    := <session_id>,<user_id>,<token>,<last_hit>
#   ad_user_login    := <user_id>,<password:hexified>
#   ad_secure_token  := <secure_token>

util_report_library_entry

proc_doc sec_hexify { data } { Formats a string as a series of hexadecimal digits, e.g., "ABC" becomes "313233". } {
    set out ""
    for { set i 0 } { $i < [string length $data] } { incr i } {
	scan [string index $data $i] "%c" val
	append out [format "%02X" $val]
    }
    return $out
}

proc_doc sec_dehexify { data } { Turns a series of hexadecimal digits into a string, e.g., "313233" becomes "ABC". This is the inverse of sec_hexify. } {
    set out ""
    for { set i 0 } { $i < [string length $data] } { set i [expr { $i + 2 }] } {
	scan [string range $data $i [expr { $i + 1 }]] "%x" val
	append out [format "%c" $val]
    }
    return $out
}

proc ad_crypt_salt {} {
    return [ad_parameter CryptSalt "" "fb"]
}

proc_doc sec_random_char {} { Returns a random character which can be used for a password or token. } {
    return [string index "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz./" [ns_rand 64]]
}

proc_doc sec_random_token {} { Generates a random token, using the TokenLength as the token length. } {
    set token ""
    set length [ad_parameter TokenLength "" 32]
    for { set i 0 } { $i < $length } { incr i } {
	append token [sec_random_char]
    }
    return $token
}

proc_doc sec_session_timeout {} { Returns the timeout, in seconds, for sessions. } {
    return [ad_parameter SessionTimeout "" 86400]
}

proc_doc sec_session_cookie_reissue {} { Returns the period, in seconds, after which we should reissue the session_id cookie and update last_hit in the sessions table. } {
    return [ad_parameter SessionCookieReissue "" 600 ]
}

proc sec_sweep_sessions {} {
    set db [ns_db gethandle log]
    ns_db dml $db "
        delete from sec_sessions
        where  [ns_time] - last_hit > [ad_parameter SessionLifetime "" 176800]
    "
    ns_db releasehandle $db
}

nsv_set ad_security . ""
if { ![nsv_exists ad_security inited] } {
    nsv_set ad_security inited 1

    # Register the security filters (critical and high-priority).
    ad_register_filter -critical t -priority 1 preauth * /* sec_read_security_info
    ad_register_filter -critical t -priority 1 trace * /* ad_issue_deferred_dml

    # Schedule a procedure to sweep for sessions.
    ad_schedule_proc -thread t [ad_parameter SessionSweepInterval "" 3600] sec_sweep_sessions
}

proc_doc ad_issue_deferred_dml { conn args why } { Issue deferred DML statements registered by ad_defer_dml. } {
    global ad_sec_deferred_dml

    if { [llength $ad_sec_deferred_dml] > 0 } {
	set db [ns_db gethandle log]
	foreach item $ad_sec_deferred_dml {
	    set sql [lindex $item 0]
	    set blobs [lindex $item 1]
	    if { [llength $blobs] == 0 } {
		# No blobs; just perform a plain old DML.
		ns_db dml $db $sql
	    } else {
		# Has blobs; use clob_dml.
		eval [concat [list ns_ora clob_dml $db $sql] $blobs]
	    }
	}
	ns_db releasehandle $db
    }

    return "filter_ok"
}

proc_doc ad_defer_dml { sql { blobs "" } } { Registers a DML call to be issued at connection close. Will use ns_ora clob_dml if blobs are provided, else ns_db dml. } {
    global ad_sec_deferred_dml
    lappend ad_sec_deferred_dml [list $sql $blobs]
}

proc ad_dump_security_info { db } {
    # Debugging procedure to dump a table with some important security information.
    set out "
<table border=2 cellpadding=10><tr><td>
  <table cellspacing=0 cellpadding=0>
"
    
    foreach var { ad_sec_validated ad_sec_browser_id ad_sec_session_id ad_sec_user_id } {
	global $var
	append out "<tr><th align=left>\$$var:</th><td>&nbsp;&nbsp;&nbsp;</td><td>[set $var]</td></tr>\n"
    }

    append out "<tr><th colspan=3><hr>Cookies:<br><br></th></tr>\n"
    foreach cookie [split [ns_set iget [ns_conn headers] "Cookie"] "; "] {
	if { [regexp {^([^=]+)=(.+)$} $cookie match name value] } {
	    append out "<tr><th align=left>$name:</th><td>&nbsp;&nbsp;&nbsp;</td><td>$value</td></tr>\n"
	}
    }

    append out "<tr><th colspan=3><br><a href=\"/sec/clear-cookies.tcl\">Clear All</a> | <a href=\"/sec/clear-cookies.tcl?session_only=1\">Clear Session Only</a><hr>Setting Cookies:<br><br></th></tr>\n"
    set headers [ns_conn outputheaders]
    for { set i 0 } { $i < [ns_set size $headers] } { incr i } {
	if { ![string compare [string tolower [ns_set key $headers $i]] "set-cookie"] } {
	    if { [regexp {^([^=]+)=(.+)$} [ns_set value $headers $i] match name value] } {
		append out "<tr><th align=left>$name:</th><td>&nbsp;&nbsp;&nbsp;</td><td>$value</td></tr>\n"
	    }
	}
    }

    append out "<tr><th colspan=3><hr>In database:<br><br></th></tr>\n"

    set selection [ns_db 0or1row $db "select * from sec_sessions where session_id = $ad_sec_session_id"]
    if { $selection != "" } {
	for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
	    append out "<tr><th align=left>[ns_set key $selection $i]:</th>
<td>&nbsp;&nbsp;&nbsp;</td><td>[ns_set value $selection $i]</td></tr>
"
        }
    }

    append out "<tr><th colspan=3><hr>Session properties:<br><br></th></tr>\n"

    set selection [ns_db select $db "
        select module, property_name, property_value, secure_p
        from sec_session_properties
        where session_id = $ad_sec_session_id
        order by module, property_name
    "]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append out "<tr><th align=left>${module}/$property_name"
	if { $secure_p == "t" } {
	    append out " (secure)"
	}
	append out ":</td><td>&nbsp;&nbsp;&nbsp;</td><td>$property_value</td></tr>\n"
    }

    append out "<tr><th colspan=3><hr>Browser properties:<br><br></th></tr>\n"

    set selection [ns_db select $db "
        select module, property_name, property_value, secure_p
        from sec_browser_properties
        where browser_id = $ad_sec_browser_id
        order by module, property_name
    "]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append out "<tr><th align=left>${module}/$property_name"
	if { $secure_p == "t" } {
	    append out " (secure)"
	}
	append out ":</td><td>&nbsp;&nbsp;&nbsp;</td><td>$property_value</td></tr>\n"
    }

    append out "
  </table>
</td></tr></table>
"

    return $out
}

ad_proc ad_user_login {
    { -forever f }
    db user_id
} { Logs the user in, forever (via the user_login cookie) if -forever is true. } {
    global ad_sec_user_id
    set ad_sec_user_id $user_id

    set user_id_for_update [ad_decode $user_id 0 "null" $user_id]

    sec_generate_session_id_cookie
    ns_db dml $db "
        update sec_sessions
        set user_id = $user_id_for_update
        where session_id = [ad_get_session_id]
    "
    util_memoize_flush "sec_get_session_info [ad_get_session_id]"

    if { $forever == "t" && $user_id != 0 } {
	if { [ad_secure_conn_p] } {
	    set secure "t"
	} else {
	    set secure "f"
	}
	set password [database_to_tcl_string $db "select password from users where user_id = $user_id"]
	ad_set_cookie -expires never -secure $secure \
		"ad_user_login" "$user_id,[sec_hexify $password]"
    }
}

proc_doc ad_user_logout { db } { Logs the user out. } {
    ad_user_login $db 0
}

proc_doc ad_check_password { db user_id password_from_form } { Returns 1 if the password is correct for the given user ID. } {
    set selection [ns_db 0or1row $db "
        select password
        from users
        where user_id = $user_id
        and user_state='authorized'
    "]

    if {$selection == ""} {
	return 0
    }

    set_variables_after_query

    # If we are encrypting passwords in the database, convert so we can compare
    if  [ad_parameter EncryptPasswordsInDBP "" 0] { 
	set password_from_form [ns_crypt $password_from_form [ad_crypt_salt]]
    }

    if { [string compare [string toupper $password_from_form] [string toupper $password]] } {
	return 0
    }

    return 1
}
    
proc sec_log { str } {
    set must_match [ad_parameter LogSecurityMinutia "" ""]
    if { [string match $must_match [ns_conn peeraddr]] } {
	ns_log "Notice" "SecurityMinutia \[[ns_conn peeraddr]\]: $str"
    }
}

proc_doc ad_assign_session_id { db } { Sets up the session, setting the global variables and issuing a cookie if necessary. } {
    global ad_sec_browser_id
    global ad_sec_validated
    global ad_sec_session_id
    global ad_sec_user_id
    global ad_sec_token

    # Generate all the information we need to create the session.
    set ad_sec_session_id [database_to_tcl_string $db "select sec_id_seq.nextval from dual"]
    set ad_sec_token [sec_random_token]
    sec_log "Generating new session_id $ad_sec_session_id."

    if { [ad_secure_conn_p] } {
	# Secure session - generate the secure token.
	set secure_token [sec_random_token]
	sec_generate_secure_token_cookie $secure_token
    } else {
	set secure_token ""
    }

    set ad_sec_user_id 0
    if { [regexp {^([0-9]+),([0-9a-fA-F]+)$} [ad_get_cookie "ad_user_login"] match user_id password] } {
	if { [ad_parameter EncryptPasswordsInDBP "" 0] } { 
	    set password [ns_crypt $password [ad_crypt_salt]]
	}

	set selection [ns_db 0or1row $db "
	select password
	from users
	where user_id = $user_id
	and user_state = 'authorized'
	"]

	if { [empty_string_p $selection] } {
	    # user_id does not exist in database, or is not in state authorized
	    
	} else {
	    set correct_password [ns_set value $selection 0]

	    set password_raw [sec_dehexify $password]
	    if { ![string compare [string toupper $correct_password] [string toupper $password_raw]] } {
		set ad_sec_user_id $user_id
	    }
	}
    }

    if { $ad_sec_user_id == 0 } {
	set insert_id "null"
    } else {
	set insert_id $ad_sec_user_id
    }

    ns_db dml $db "
    insert into sec_sessions(session_id, user_id, token, secure_token, browser_id,
    last_ip, last_hit)
    values($ad_sec_session_id, $insert_id, '$ad_sec_token', '$secure_token', $ad_sec_browser_id,
    '[ns_conn peeraddr]', [ns_time])
    "

    if { [ad_secure_conn_p] } {
	set ad_sec_validated "secure"
    } else {
	set ad_sec_validated "insecure"
    }

    sec_generate_session_id_cookie

    # Update last_visit and second_to_last_visit
    ns_db dml $db "begin sec_rotate_last_visit($ad_sec_browser_id, [ns_time]); end;"
}

proc_doc ad_conn { which } { Returns a property about the connection. Allowable values are:

<ul>
  <li><tt><b>canonicalurl</b></tt>: Returns a canonical URL for the request, containing all scoping information and the file's extension.
  <li><tt><b>file</b></tt>: Returns the absolute path to the file delivered.
  <li><tt><b>extension</b></tt>: Returns the extension of the file delivered.
</ul>

Currently these properties become available only when a file is sourced by the abstract URL handler,
although this limitation will be removed in the next release as we extend the request processing
pipeline.

} {
    global ad_conn
    switch $which {
	url - file - canonicalurl {
	    if { [info exists ad_conn($which)] } {
		return $ad_conn($which)
	    } else {
		return ""
	    }
	}
	extension {
	    if { [info exists ad_conn(file)] } {
		return [file extension $ad_conn(file)]
	    } else {
		return ""
	    }
	}
    }

    error "ad_conn $which is invalid; should be canonicalurl, file, or extension"
}

proc_doc sec_read_security_info { conn args why } { The security filter, initializing the session. } {
    global ad_sec_validated
    set ad_sec_validated ""

    global ad_sec_browser_id
    set ad_sec_browser_id ""
    global ad_sec_session_id
    set ad_sec_session_id ""
    global ad_sec_user_id
    set ad_sec_user_id 0
    global ad_sec_token
    set ad_sec_token ""

    global ad_sec_deferred_dml
    set ad_sec_deferred_dml ""

    global ad_conn
    if { [info exists ad_conn] } {
	unset ad_conn
    }
    set ad_conn(.) ""

    # Don't bother doing *anything* for requests to /SYSTEM.
    if { [lindex [ns_conn urlv] 0] == "SYSTEM" } {
	return "filter_ok"
    }

    # Force the URL to look like [ns_conn location], if desired...
    if { [ad_parameter ForceHostP "" 1] } {
	set host_header [ns_set iget [ns_conn headers] "Host"]
	regexp {^([^:]*)} $host_header "" host_no_port
	regexp {^https?://([^:]+)} [ns_conn location] "" desired_host_no_port
	if { $host_header != "" && [string compare $host_no_port $desired_host_no_port] } {
	    sec_log "Host header is set to \"$host_header\"; forcing to \"[ns_conn location]\""
	    set query [ns_conn query]
	    if { $query != "" } {
		set query "?$query"
		if { [ns_getform] != "" } {
		    set query "$query&[export_entire_form_as_url_vars]"
		}
	    } elseif { [ns_getform] != "" } { 
		set query "?[export_entire_form_as_url_vars]"
	    }
	    ad_returnredirect "[ns_conn location][ns_conn url]$query"
	    return "filter_return"
	}
    }

    regexp {^([0-9]+)$} [ad_get_cookie "ad_browser_id"] match ad_sec_browser_id
    regexp {^([0-9]+),([0-9]*),([^,]*),([0-9]+)$} \
	    [ad_get_cookie "ad_session_id"] match ad_sec_session_id ad_sec_user_id ad_sec_token last_issue

    sec_log "sec_read_security_info: ad_browser_id=<<[ad_get_cookie "ad_browser_id"]>>; ad_session_id=<<[ad_get_cookie "ad_session_id"]>>"

    if { $ad_sec_browser_id == "" } {
	set db [ns_db gethandle]
	set ad_sec_browser_id [database_to_tcl_string $db "select sec_id_seq.nextval from dual"]
	sec_log "Generating new browser_id $ad_sec_browser_id"
	ad_set_cookie -expires never "ad_browser_id" $ad_sec_browser_id
    }

    if { $ad_sec_session_id == "" || \
	    $last_issue > [ns_time] + [sec_session_timeout] || \
            $last_issue + [sec_session_timeout] < [ns_time] } {
	# No session or user ID yet (or last_issue is way in the future, or session is expired).

	if { ![info exists last_issue] } {
	    set last_issue ""
	}

	if { ![info exists db] } {
	    set db [ns_db gethandle]
	}
	sec_log "Bad session: session ID was \"$ad_sec_session_id\"; last_issue was \"$last_issue\"; ns_time is [ns_time]; timeout is [sec_session_timeout]"

	ad_assign_session_id $db
    } else {
	# The session already exists. 

	if { $last_issue + [sec_session_cookie_reissue] < [ns_time] } {
	    ad_defer_dml "
                update sec_sessions
                set last_hit = [ns_time]
                where session_id = $ad_sec_session_id
            "
	    util_memoize_flush "sec_get_session_info $ad_sec_session_id"
	    sec_generate_session_id_cookie
	}
    }

    if { [info exists db] } {
	ns_db releasehandle $db
    }

    if { [regexp {^/pvt/} [ns_conn url]] && [ad_verify_and_get_user_id] == 0 } {
	ad_redirect_for_registration
	return "filter_return"
    }

    return "filter_ok"
}

proc_doc sec_lookup_property { browser id module name } { Used as a helper procedure for util_memoize to look up a particular property from the database. Returns [list $property_value $secure_p]. } {
    set kind [ad_decode $browser "t" "browser" "session"]

    set db [ns_db gethandle log]
    set selection [ns_db 0or1row $db "
        select property_value, secure_p
        from sec_${kind}_properties
        where ${kind}_id = '[DoubleApos $id]'
        and module = '[DoubleApos $module]'
        and property_name = '[DoubleApos $name]'
    "]
    if { $selection == "" } {
	ns_db releasehandle $db
	return ""
    }

    set_variables_after_query
    ns_db releasehandle $db
    return [list $property_value $secure_p]
}

ad_proc ad_get_client_property {
    {
	-cache t
	-browser f
        -cache_only f
    }
    module
    name
} { Looks up a property for the current session, or for the browser. If $cache is true, will use the cached value if available. If $cache_only is true, will never incur a database hit (i.e., will only return a value if cached). If the property is secure, we must be on a validated session over SSL. } {
    set id [ad_decode $browser "t" [ad_get_browser_id] [ad_get_session_id]]

    set cmd [list sec_lookup_property $browser $id $module $name]

    if { $cache_only == "t" && ![util_memoize_value_cached_p $cmd] } {
	return ""
    }

    if { $cache != "t" } {
	util_memoize_flush $cmd
    }

    set property [util_memoize $cmd [sec_session_timeout]]
    if { $property == "" } {
	return ""
    }
    set value [lindex $property 0]
    set secure_p [lindex $property 1]
    
    global ad_sec_validated
    if { $secure_p != "f" && $ad_sec_validated != "secure" } {
	return ""
    }

    return $value
}

ad_proc ad_set_client_property { 
    {
	-secure f
	-browser f
	-deferred f
	-persistent t
    }
    module name value
} { Sets a client (session- or browser-level) property. If $persistent is true, the new value will be written through to the database. If $deferred is true, the database write will be delayed until connection close (although calls to ad_get_client_property will still return the correct value immediately). If $secure is true, the property will not be retrievable except via a validated, secure (HTTPS) connection. } {
    global ad_sec_validated
    if { $secure != "f" && $ad_sec_validated != "secure" } {
	error "Unable to set secure property in insecure or invalid session"
    }

    set kind [ad_decode $browser "t" "browser" "session"]

    if { $persistent == "t" } {
	# Write to database - either defer, or write immediately. First delete the old
	# value if any; then insert the new one.

	set dml "
            delete from sec_${kind}_properties
            where ${kind}_id = [ad_get_${kind}_id]
            and module = '[DoubleApos $module]'
            and property_name = '[DoubleApos $name]'
        "
        if { $deferred == "t" } {
	    ad_defer_dml $dml
        } else {
	    set db [ns_db gethandle log]
	    ns_db dml $db "begin transaction"
	    ns_db dml $db $dml
        }

        set dml "
            insert into sec_${kind}_properties(${kind}_id, module, property_name, property_value, secure_p)
            values([ad_get_${kind}_id], '[DoubleApos $module]', '[DoubleApos $name]', empty_clob(), '[DoubleApos $secure]')
            returning property_value into :1
	"
        if { $deferred == "t" } {
	    ad_defer_dml $dml [list $value]
        } else {
	    ns_ora clob_dml $db $dml $value
	    ns_db dml $db "end transaction"
	    ns_db releasehandle $db
        }
    }

    # Remember the new value, seeding the memoize cache with the proper value.
    util_memoize_seed [list sec_lookup_property $browser [ad_get_session_id] $module $name] [list $value $secure]
}

proc_doc ad_secure_conn_p {} { Returns true if the connection [ns_conn] is secure (HTTPS), or false otherwise. } {
    return [regexp {^https:} [ns_conn location]]
}

proc_doc sec_generate_secure_token_cookie { secure_token } { Sets the ad_secure_token cookie. } {
    # Sanity check - make sure we're using HTTPS.
    if { [ad_secure_conn_p] } {
	ad_set_cookie -secure t "ad_secure_token" $secure_token
    }
}

proc_doc sec_generate_session_id_cookie {} { Sets the ad_session_id cookie based on global variables. } {
    global ad_sec_session_id
    global ad_sec_user_id
    global ad_sec_token
    ad_set_cookie -replace t -max_age [sec_session_timeout] \
	    "ad_session_id" "$ad_sec_session_id,$ad_sec_user_id,$ad_sec_token,[ns_time]"
}

proc_doc sec_get_session_info { session_id } { Returns information for a session, in the form [list $user_id $token $secure_token $last_ip $last_hit]. } {
    set db [ns_db gethandle log]

    set sql "
        select user_id, token, secure_token,
               last_ip, last_hit from sec_sessions
        where session_id = $session_id
    "

    set selection [ns_db 0or1row $db $sql]
    ns_db releasehandle $db

    if { $selection == "" } {
	sec_log "No row in sec_sessions for session_id $session_id!"
	return
    }

    set_variables_after_query
    return [list $user_id $token $secure_token $last_ip $last_hit]
}

ad_proc ad_validate_security_info {
    { -secure f }
} { Validates the security info for the current connection, including session and user ID. If -secure t is specified, requires that the security info be secure to be considered valid. } {
    global ad_sec_validated
    global ad_sec_browser_id
    global ad_sec_session_id
    global ad_sec_user_id
    global ad_sec_token

    if { $ad_sec_validated == "secure" || ( $secure == "f" && $ad_sec_validated == "insecure" ) } {
	return 1
    }

    set security_info [util_memoize "sec_get_session_info $ad_sec_session_id" \
	    [ad_parameter "SessionInfoCacheInterval" "" 600]]
    if { $security_info == "" } {
	set db [ns_db gethandle log]
	ad_assign_session_id $db
	ns_db releasehandle $db
	set security_info [util_memoize "sec_get_session_info $ad_sec_session_id" \
		[ad_parameter "SessionInfoCacheInterval" "" 600]]
    }

    set user_id [lindex $security_info 0]
    set token [lindex $security_info 1]
    set secure_token [lindex $security_info 2]
    set last_ip [lindex $security_info 3]
    set last_hit [lindex $security_info 4]

    if { $user_id == "" } {
	set user_id 0
    }

    # We don't compare $last_ip, since some proxies rotate IP addresses. Thanks to lars@pinds.com.
    if { $last_hit + [sec_session_timeout] < [ns_time] || $user_id != $ad_sec_user_id } {
	return 0
    }

    # If the insecure token doesn't match, bail out.
    if { [string compare $token $ad_sec_token] } {
	return 0
    }

    if { $secure == "f" } {
	# Passed with flying colors (for insecure validation).
	set ad_sec_validated "insecure"
    } else {
	if { ![ad_secure_conn_p] } {
	    # An insecure connection can't be securely validated.
	    return 0
	}

	if { [empty_string_p $secure_token] } {
	    # Secure token not yet assigned. Generate it; also regenerate insecure token.

	    set ad_sec_token [sec_random_token]
	    set secure_token [sec_random_token]

	    set db [ns_db gethandle log]
	    ns_db dml $db "
                update sec_sessions
                set token = '$ad_sec_token', secure_token = '$secure_token'
                where session_id = $ad_sec_session_id
	    "
	    ns_db releasehandle $db
	    util_memoize_seed "sec_get_session_info $ad_sec_session_id" [list $user_id $ad_sec_token $secure_token $last_ip $last_hit]

	    sec_generate_session_id_cookie
	    sec_generate_secure_token_cookie $secure_token
	} elseif { [string compare [ad_get_cookie "ad_secure_token"] $secure_token] } {
	    # Secure token doesn't mack. Nice try, sucka.
	    return 0
	}
	set ad_sec_validated "secure"
    }
    return 1
}

proc ad_verify_identity { conn args why } {
    set user_id [ad_verify_and_get_user_id]
    if {$user_id > 0} {
	# password checked out
	return filter_ok
    }
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
    return filter_return
}

proc_doc ad_get_user_id {} "Gets the user ID, without checking to see whether it is valid. This procedure shouldn't be used for any page where security is important." {
    global ad_sec_user_id
    return $ad_sec_user_id
}

proc_doc ad_get_session_id {} "Gets the session ID, without checking to see whether it is valid. This procedure shouldn't be used for any page where security is important." {
    global ad_sec_session_id
    return $ad_sec_session_id
}

proc_doc ad_get_browser_id {} "Gets the browser ID." {
    global ad_sec_browser_id
    return $ad_sec_browser_id
}

ad_proc ad_verify_and_get_user_id {
    { -secure f }
    { db "" }
} "Returns the current user's ID, verifying its validity (or returning 0 if unable to do so)." {
    if { ![ad_validate_security_info -secure $secure] } {
	return 0
    }
    return [ad_get_user_id]
}

ad_proc ad_verify_and_get_session_id {
    { -secure f }
    { db "" }
} "Returns the current session's ID, verifying its validity (or returning 0 if unable to do so)." {
    if { ![ad_validate_security_info -secure $secure] } {
	return 0
    }
    return [ad_get_session_id]
}

# handling privacy

proc_doc ad_privacy_threshold {} "Pages that are consider whether to display a user's name or email address should test to make sure that a user's priv_ from the database is less than or equal to what ad_privacy_threshold returns." {
    set session_user_id [ad_get_user_id]
    if {$session_user_id == 0} {
	# viewer of this page isn't logged in, only show stuff 
	# that is extremely unprivate
	set privacy_threshold 0
    } else {
	set privacy_threshold 5
    }
    return $privacy_threshold
}


proc_doc ad_redirect_for_registration {} "Redirects user to /register/index.tcl to require the user to register. When registration is complete, the user will be returned to the current location.  All variables in ns_getform (both posts and gets) will be maintained." {
    set form [ns_getform] 
    set url_args ""
    
    # note that there is no built-in function that will change
    # posted variables to url variables, so we write our own
    
    if ![empty_string_p $form] {
	set form_size [ns_set size $form]
	set form_counter_i 0
	while { $form_counter_i<$form_size } {
	    if {[string compare $form_counter_i "0"] == 0} {
		append url_args "?"
	    } else {
		append url_args "&"
	    }
	    append url_args "[ns_set key $form $form_counter_i]=[ns_urlencode [ns_set value $form $form_counter_i]]"
	    incr form_counter_i
	}
    }
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]$url_args]"
    return
}

proc_doc ad_maybe_redirect_for_registration {} "Checks to see if a user is logged in.  If not, redirects to /register/index.tcl to require the user to register. When registration is complete, the user will return to the current location.  All variables in ns_getform (both posts and gets) will be maintained.  Note that this will return out of its caller so that the caller need not explicitly call \"return\". Returns the user id if login was succesful." {
    set user_id [ad_verify_and_get_user_id]
    if { $user_id != 0 } {
	# user is in fact logged in, terminate
	return $user_id
    }
    ad_redirect_for_registration
    
    # blow out of 2 levels
    return -code return
}

# bouncing people out of content_sections that are private
# we can't just run this in-line because the ns_db calls aren't defined while Private
# Tcl is being sourced 

proc ad_filter_restricted_content_sections {} {
    # let's also bounce them out of private content sections 
    set db [ns_db gethandle]
    set selection [ns_db select $db "
    select section_url_stub 
    from content_sections
    where scope='public'
    and requires_registration_p = 't'"]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_log Notice "Going to filter out access to $section_url_stub, marked as requiring registration in the content_sections table"
	ad_register_filter preauth HEAD "${section_url_stub}*" ad_verify_identity
	ad_register_filter preauth GET "${section_url_stub}*" ad_verify_identity
	ad_register_filter preauth POST "${section_url_stub}*" ad_verify_identity
    }
    ns_db releasehandle $db
}

ad_schedule_proc -once t 5 ad_filter_restricted_content_sections

# sort of the same idea as the above but for things like staff
# servers where the whole site may be restricted

ns_share -init {set ad_restrict_entire_server_to_registered_users_registered_p 0} ad_restrict_entire_server_to_registered_users_registered_p

if {[ad_parameter RestrictEntireServerToRegisteredUsersP "" 0] && !$ad_restrict_entire_server_to_registered_users_registered_p} {
    # we don't want to keep registering filters every time the server is re-initialize
    set ad_restrict_entire_server_to_registered_users_registered_p 1
    ns_log Notice "ad-security.tcl is registering ad_restrict_entire_server_to_registered_users to bounce unregistered users out of pretty much everything."
    ad_register_filter preauth GET /* ad_restrict_entire_server_to_registered_users
    ad_register_filter preauth POST /* ad_restrict_entire_server_to_registered_users
    ad_register_filter preauth HEAD /* ad_restrict_entire_server_to_registered_users
}

proc_doc ad_restrict_entire_server_to_registered_users {conn args why} "A preauth filter that will halt service of any page if the user is unregistered, except the site index page and stuff underneath /register" {
    if {![string match "/index.tcl" [ns_conn url]] && ![string match "/" [ns_conn url]] && ![string match "/register/*" [ns_conn url]] && ![string match "/SYSTEM/*" [ns_conn url]] && ![string match "/cookie-chain*" [ns_conn url]] && ![string match "/user_please_login.tcl" [ns_conn url]]} {
	# not one of the magic acceptable URLs
	set user_id [ad_verify_and_get_user_id]
	if {$user_id == 0} {
	    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	    return filter_return
	}
    }
    return filter_ok
}


## generating a random string

proc_doc ad_generate_random_string {{length 8}} "Generates a random string made of numbers and letters" {
    set password ""

    set character_list [list a b c d e f g h i j k m n p q r s t u v w x y z A B C D E F G H I J K L M N P Q R S T U V W X Y Z 2 3 4 5 6 7 8 9]

    for {set random_string_counter 0} {$random_string_counter < $length} {incr random_string_counter } {
	set chosen_index [randomRange [llength $character_list]]
	append password [lindex $character_list $chosen_index]
    }
    return $password
}



util_report_successful_library_load










