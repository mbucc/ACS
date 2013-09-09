# /packages/acs-core/security-procs.tcl

ad_library {

    Provides methods for authorizing and identifying ACS users
    (both logged in and not) and tracking their sessions.

    @creation-date 16 Feb 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id security-procs.tcl,v 1.15.2.23 2001/01/13 01:19:01 khy Exp
}

# Cookies:
#
#   ad_browser_id    := <browser_id>
#   ad_session_id    := <session_id>,<user_id>,<token>,<last_hit>
#   ad_user_login    := <user_id>,<permanent_login_token>
#   ad_secure_token  := <secure_token>

proc_doc sec_random_char {} { Returns a random character which can be used for a password or token. } {
    return [string index "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz./" [ns_rand 64]]
}

proc_doc sec_digest_string { str } { Digests a string into eight ASCII characters (horribly insecurely). This is fed to ns_crypt to help generate random data. } {
    set chars [list 32 32 32 32 32 32 32 32]
    for { set i 0 } { $i < [string length $str] } { incr i } {
	scan [string index $str $i] "%c" chr
	set index [expr { $i % 8 }]
	set chars [lreplace $chars $index $index [expr { [lindex $chars $index] + $chr }]]
    }
    foreach chr $chars {
	append out [format "%c" [expr { $chr % 93 + 33 }]]
    }
    return $out
}

proc_doc sec_random_token {} { Generates a random token. } {
    # tcl_sec_seed is used to maintain a small subset of the previously
    # generated random token to use as the seed for the next
    # token. this makes finding a pattern in sec_random_token harder
    # to guess when it is called multiple times in the same thread.
    global tcl_sec_seed
    global ad_conn
    
    if { [info exists ad_conn(request)] } {
        set request [ad_conn request]
    } else {
	set request "yoursponsoredadvertisementhere"
    }

    if { [info exists ad_conn(start_clicks)] } {
	set start_clicks [ad_conn start_clicks]
    } else {
	set start_clicks "developer.arsdigita.com"
    }
    
    if { ![info exists tcl_sec_seed] } {
	set tcl_sec_seed "listentowmbr89.1"
    }

    set random_base [ns_sha1 "[ns_time][ns_rand]$start_clicks$request$tcl_sec_seed"]
    set tcl_sec_seed [string range $random_base 0 10]
    
    return [ns_sha1 [string range $random_base 11 39]]
}

ad_proc -public ad_sign {
    {
	-secret ""
	-token_id ""
	-max_age ""
    }
    value
} {
    Returns a digital signature of the value. Negative token_ids are
    reserved for secrets external to the ACS digital signature
    mechanism. If a token_id is specified, a secret must also be
    specified.

    @param max_age specifies the length of time the signature is
    valid in seconds. The default is forever.

    @param secret allows the caller to specify a known secret external
    to the random secret management mechanism.

    @param token_id allows the caller to specify a token_id.

    @param value the value to be signed.
} {
    # pick a random token_id
    if { [empty_string_p $secret] } {
	set token_id [sec_get_random_cached_token_id]
	set secret_token [sec_get_token $token_id]
    } else {
	set secret_token $secret
    }

    ns_log Debug "Security: Getting token_id $token_id, value $secret_token"

    if { $max_age == "" } {
	set expire_time 0
    } else {
	set expire_time [expr $max_age + [ns_time]]
    }

    set hash [ns_sha1 "$value$token_id$expire_time$secret_token"]

    set signature [list $token_id $expire_time $hash]

    return $signature
}

ad_proc -public ad_verify_signature {
    {
	-secret ""
    }
    value signature
} {
    Verifies a digital signature. Returns 1 for success, and 0 for
    failed validation. Validation can fail due to tampering or
    expiration of signature.

    @param secret specifies an external secret to use instead of the
    one provided by the ACS signature mechanism.
} {
    set token_id [lindex $signature 0]
    set expire_time [lindex $signature 1]
    set hash [lindex $signature 2]

    return [__ad_verify_signature $value $token_id $secret $expire_time $hash]

}


ad_proc -public ad_verify_signature_with_expr {
    {
	-secret ""
    }
    value signature
} {
    Verifies a digital signature. Returns either the expiration time
    or 0 if the validation fails.

    @param secret specifies an external secret to use instead of the
    one provided by the ACS signature mechanism.
} {
    set token_id [lindex $signature 0]
    set expire_time [lindex $signature 1]
    set hash [lindex $signature 2]

    if { [__ad_verify_signature $value $token_id $secret $expire_time $hash] } {
	return $expire_time
    } else {
	return 0
    }

}

ad_proc -private __ad_verify_signature {
    value
    token_id
    secret
    expire_time
    hash
} {
    
    Returns 1 if signature validated; 0 if it fails.

} {

    if { [empty_string_p $secret] } {
	set secret_token [sec_get_token $token_id]
    } else {
	set secret_token $secret
    }

    ns_log Debug "Security: Getting token_id $token_id, value $secret_token"
    ns_log Debug "Security: Expire_Time is $expire_time (compare to [ns_time]), hash is $hash"

    # validate cookie: verify hash and expire_time
    set computed_hash [ns_sha1 "$value$token_id$expire_time$secret_token"]

    if { [string compare $computed_hash $hash] == 0 && ($expire_time > [ns_time] || $expire_time == 0) } {
	return 1
    }

    ns_log Debug "Security: The string compare is [string compare $computed_hash $hash]."
    # signature could not be authenticated
    return 0

}
ad_proc -public ad_get_signed_cookie {
    { 
	-include_set_cookies t 
	-secret ""
    }
    name
} { 

    Retrieves a signed cookie. Validates a cookie against its
    cryptographic signature and insures that the cookie has not
    expired. Throws an exception if validation fails.

} {

    if { $include_set_cookies == "t" } {
	set cookie_value [ns_urldecode [ad_get_cookie $name]]
    } else {
	set cookie_value [ns_urldecode [ad_get_cookie -include_set_cookies f $name]]
    }

    if { [empty_string_p $cookie_value] } {
	error "Cookie does not exist."
    }

    ns_log Debug "Security: Done calling get_cookie $cookie_value for $name."

    set value [lindex $cookie_value 0]
    set signature [lindex $cookie_value 1]

    if { [ad_verify_signature $value $signature] } {
	return $value
    }

    error "Cookie could not be authenticated."
}

ad_proc -public ad_get_signed_cookie_with_expr {
    { 
	-include_set_cookies t 
	-secret ""
    }
    name
} { 

    Retrieves a signed cookie. Validates a cookie against its
    cryptographic signature and insures that the cookie has not
    expired. Returns a two-element list, the first element of which is
    the cookie data, and the second element of which is the expiration
    time. Throws an exception if validation fails.

} {

    if { $include_set_cookies == "t" } {
	set cookie_value [ns_urldecode [ad_get_cookie $name]]
    } else {
	set cookie_value [ns_urldecode [ad_get_cookie -include_set_cookies f $name]]
    }

    if { [empty_string_p $cookie_value] } {
	error "Cookie does not exist."
    }

    set value [lindex $cookie_value 0]
    set signature [lindex $cookie_value 1]

    set expr_time [ad_verify_signature_with_expr $value $signature]

    ns_log Debug "Security: Done calling get_cookie $cookie_value for $name; received $expr_time expiration, getting $value and $signature."

    if { $expr_time } {
	return [list $value $expr_time]
    }

    error "Cookie could not be authenticated."
}

ad_proc -public ad_set_signed_cookie {
    {
	-replace f
	-secure f
	-max_age ""
	-domain ""
	-path "/"
	-secret ""
	-token_id ""
    }
    name value
} {

    Sets a signed cookie. Negative token_ids are reserved for secrets
    external to the signed cookie mechanism. If a token_id is
    specified, a secret must be specified.

    @author Richard Li (richardl@arsdigita.com)
    @creation-date 18 October 2000

    @param max_age specifies the maximum age of the cookies in
    seconds (consistent with RFC 2109). max_age inf specifies cookies
    that never expire. (see ad_set_cookie). The default is session
    cookies.

    @param secret allows the caller to specify a known secret external
    to the random secret management mechanism.

    @param token_id allows the caller to specify a token_id.

    @param value the value for the cookie. This is automatically
    url-encoded.

} {
    if { $max_age == "inf" } {
	set signature_max_age ""
    } elseif { $max_age != "" } {
	set signature_max_age $max_age
    } else {
	# this means we want a session level cookie,
	# but that is a user interface expiration, that does
	# not give us a security expiration. (from the
	# security perspective, we use SessionLifetime)
	ns_log Debug "Security: SetSignedCookie: Using sec_session_lifetime [sec_session_lifetime]"
	set signature_max_age [sec_session_lifetime]
    }

    set cookie_value [ad_sign -secret $secret -token_id $token_id -max_age $signature_max_age $value]

    set data [ns_urlencode [list $value $cookie_value]]

    ad_set_cookie -replace $replace -secure $secure -max_age $max_age -domain $domain -path $path $name $data
}

ad_proc sec_get_token { token_id } {

    Returns the token corresponding to the token_id. This first checks
    the thread-persistent TCL cache, then checks the server
    size-limited cache before finally hitting the db in the worst case
    if the secret_token value is not in either cache. The procedure
    also updates the caches.

    Cache eviction is handled by the ns_cache API for the size-limited
    cache and is handled by AOLserver (via thread termination) for the
    thread-persistent TCL cache.

} {
    
    global tcl_secret_tokens

    if { [info exists tcl_secret_tokens($token_id)] } {
	return $tcl_secret_tokens($token_id)
    } else {
	set token [ns_cache eval secret_tokens $token_id {
	    return [db_string get_token {select token from secret_tokens
                       	                 where token_id = :token_id} -default 0]
	}]

        if { $token == 0 } {
	    error "Invalid token ID"
	}

	set tcl_secret_tokens($token_id) $token
	return $token
	
    }

}

ad_proc sec_get_random_cached_token_id {} {
    
    Randomly returns a token_id from the ns_cache.

} {
 
    set list_of_names [ns_cache names secret_tokens]
    set random_seed [ns_rand [llength $list_of_names]]

    return [lindex $list_of_names $random_seed]
    
}

ad_proc -private populate_secret_tokens_cache {} {
    
    Randomly populates the secret_tokens cache.

} {

    set num_tokens 100

    # this is called directly from security-init.tcl,
    # so it runs during the install before the data model has been loaded
    if { [db_table_exists secret_tokens] } {
	db_foreach get_secret_tokens {
	    select * from (
	    select token_id, token
	    from secret_tokens
	    sample(15)
	    ) where rownum < :num_tokens
	} {
	    ns_cache set secret_tokens $token_id $token
	}
    }
}

ad_proc -private populate_secret_tokens_db {} {

    Populates the secret_tokens table. Note that this will take awhile
    to run.

} {

    set num_tokens 100
    # we assume sample size of 10%.
    set num_tokens [expr {$num_tokens * 10}]
    set counter 0
    set list_of_tokens [list]

    # the best thing to use here would be an array_dml, except
    # that an array_dml makes it hard to use sysdate and sequences.
    while { $counter < $num_tokens } {
	set random_token [sec_random_token]

	db_dml insert_random_token {
	    insert /*+ APPEND */ into secret_tokens(token_id, token, timestamp)
	    values(sec_security_token_id_seq.nextval, :random_token, sysdate)
	}
	incr counter
    }

    db_release_unused_handles

}

proc ad_crypt_salt {} {
    return [ad_parameter CryptSalt "" "fb"]
}

proc_doc sec_session_timeout {} { Returns the timeout, in seconds, for sessions. } {
    return [ad_parameter SessionTimeout "" 86400]
}

proc_doc sec_session_cookie_reissue {} { Returns the period, in seconds, after which we should reissue the session_id cookie and update last_hit in the sessions table. } {
    return [ad_parameter SessionCookieReissue "" 600 ]
}

proc sec_sweep_sessions {} {
    if { [server_cluster_enabled_p] && ![ad_canonical_server_p] } {
	return
    } else {
	# we only sweep if this proc is being executed on the canonical
	# server if we have server clustering

	set current_time [ns_time]
	set session_life [ad_parameter SessionLifetime "" 176800]

	db_dml sessions_sweep {
            delete from sec_sessions
	    where  :current_time - last_hit > :session_life
	}
    }
}

proc_doc ad_issue_deferred_dml { conn args why } { Issue deferred DML statements registered by ad_defer_dml. } {
    global ad_conn

    if { [llength $ad_conn(deferred_dml)] > 0 } {
	foreach dml_stmt $ad_conn(deferred_dml) {
	    eval $dml_stmt
	    # just execute the dml as they have stuffed it in the
	    # conn var
	}
    }
    return "filter_ok"
}

proc_doc ad_defer_dml { args } { Registers a DML call to be issued at connection close. } {
    global ad_conn
    
    lappend ad_conn(deferred_dml) $args
}

proc ad_dump_security_info {} {
    # Debugging procedure to dump a table with some important security information.
    
    global ad_conn
    
    set out "
<table border=2 cellpadding=10><tr><td>
  <table cellspacing=0 cellpadding=0>
"
    
    foreach var { ad_conn(sec_validated) ad_conn(browser_id) ad_conn(session_id) ad_conn(user_id) } {
	append out "<tr><th align=left>\$$var:</th><td>&nbsp;&nbsp;&nbsp;</td><td>[set $var]</td></tr>\n"
    }

    append out "<tr><th colspan=3><hr>Cookies:<br><br></th></tr>\n"
    foreach cookie [split [ns_set iget [ns_conn headers] "Cookie"] "; "] {
	if { [regexp {^([^=]+)=(.+)$} $cookie "" name value] } {
	    append out "<tr><th align=left>$name:</th><td>&nbsp;&nbsp;&nbsp;</td><td>$value</td></tr>\n"
	}
    }

    append out "<tr><th colspan=3><br><a href=\"/sec/clear-cookies\">Clear All</a> | <a href=\"/sec/clear-cookies?session_only=1\">Clear Session Only</a><hr>Setting Cookies:<br><br></th></tr>\n"
    set headers [ns_conn outputheaders]
    for { set i 0 } { $i < [ns_set size $headers] } { incr i } {
	if { ![string compare [string tolower [ns_set key $headers $i]] "set-cookie"] } {
	    if { [regexp {^([^=]+)=(.+)$} [ns_set value $headers $i] "" name value] } {
		append out "<tr><th align=left>$name:</th><td>&nbsp;&nbsp;&nbsp;</td><td>$value</td></tr>\n"
	    }
	}
    }

    append out "<tr><th colspan=3><hr>In database:<br><br></th></tr>\n"

    set result_set [ns_set create]
    set session_id $ad_conn(session_id)

    if { 
	[db_0or1row session_info_select {

	    select * from sec_sessions where session_id = :session_id

	} -set_id $result_set]
    } {
	for { set i 0 } { $i < [ns_set size $result_set] } { incr i } {

	    append out "<tr><th align=left>[ns_set key $result_set $i]:</th><td>&nbsp;&nbsp;&nbsp;</td><td>[ns_set value $result_set $i]</td></tr>"

	}
    }

    append out "<tr><th colspan=3><hr>Session properties:<br><br></th></tr>\n"

    db_foreach session_properties_select {

        select module, property_name, property_value, secure_p
        from sec_session_properties
        where session_id = :session_id
        order by module, property_name

    } {

	append out "<tr><th align=left>${module}/$property_name"
	if { $secure_p == "t" } {
	    append out " (secure)"
	}
	append out ":</td><td>&nbsp;&nbsp;&nbsp;</td><td>$property_value</td></tr>\n"

    }

    append out "<tr><th colspan=3><hr>Browser properties:<br><br></th></tr>\n"

    set browser_id $ad_conn(browser_id)

    db_foreach browser_properties_select {

        select module, property_name, property_value, secure_p
        from sec_browser_properties
        where browser_id = :browser_id
        order by module, property_name

    } {

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


proc_doc sec_read_security_info {} {

Reads the security cookies, setting fields in ad_conn accordingly.

} {
    global ad_conn

    regexp {^([0-9]+)$} [ad_get_cookie "ad_browser_id"] "" ad_conn(browser_id)
    regexp {^([0-9]+),([0-9]*),([^,]*),([0-9]+)$} \
	    [ns_urldecode [ad_get_cookie "ad_session_id"]] "" \
	    ad_conn(session_id) ad_conn(user_id) ad_conn(token) ad_conn(last_issue)
}

ad_proc ad_user_login {
    { -forever f }
    { -secure f }
    user_id
} { 
    Logs the user in, forever (via the user_login cookie) if -forever is true. 
} {
    global ad_conn

    if { ![ad_validate_security_info -secure $secure] } {
	# the user must pass security checks
	return 0
    }

    set ad_conn(user_id) $user_id

    set session_id [ad_get_session_id]
    set user_id_for_update [ad_decode $user_id 0 "" $user_id]

    sec_generate_session_id_cookie

    db_dml user_login_update {
        update sec_sessions
        set user_id = :user_id_for_update
        where session_id = :session_id
    }

    util_memoize_flush "sec_get_session_info [ad_get_session_id]"

    if { $user_id == 0 } {
	# Hose the user's permanent-login token.
	ad_set_cookie -max_age 0 ad_user_login ""
    }

    if { $forever == "t" && $user_id != 0 } {
	if { [ad_secure_conn_p] } {
	    set secure "t"
	} else {
	    set secure "f"
	}
	set login_token [sec_random_token]

	# To avoid having more than one token inserted, do an INSERT WHERE
        # and then select the token back.

	db_dml login_token_insert {
            insert into sec_login_tokens(user_id, password, login_token)
	    select user_id, password, :login_token
	    from   users
	    where  user_id = :user_id
	    and    (select count(*) from sec_login_tokens where user_id = :user_id) = 0
        }

	set login_token [db_string login_token_select {
            select login_token
            from   users u, sec_login_tokens t
            where  u.user_id = :user_id
            and    t.user_id = :user_id
            and    u.password = t.password
        }]

	ad_set_cookie -expires never -secure $secure ad_user_login [ns_urlencode "$user_id,$login_token"]
    }
}

proc_doc ad_user_logout {} { Logs the user out. } {
    ad_user_login 0
}

proc_doc ad_check_password { user_id password_from_form } { Returns 1 if the password is correct for the given user ID. } {

    if { ![db_0or1row password_select {select password from users where user_id = :user_id and user_state = 'authorized'}] } {
	return 0
    }

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

proc_doc ad_assign_session_id {} { Sets up the session, setting the global variables and issuing a cookie if necessary. } {
    global ad_conn
    
    # Generate all the information we need to create the session.
    set session_id [db_nextval "sec_id_seq"]
    set ad_conn(token) [sec_random_token]
    sec_log "Generating new session_id $ad_conn(session_id)."

    if { [ad_secure_conn_p] } {
	# Secure session - generate the secure token.
	set secure_token [sec_random_token]
	sec_generate_secure_token_cookie $secure_token
    } else {
	set secure_token ""
    }

    set ad_conn(user_id) 0
    if { [regexp {^([0-9]+),(.+)$} [ns_urldecode [ad_get_cookie "ad_user_login"]] \
	    "" user_id login_token] } {

	if { [db_string login_tokens_count {
	    select count(1)
            from   users u, sec_login_tokens t
            where  t.user_id = :user_id
            and    u.user_id = :user_id
            and    t.password = u.password
            and    t.login_token = :login_token
        }] } {
	    set ad_conn(user_id) $user_id
	}
    }

    if { $ad_conn(user_id) == 0 } {
	set insert_id [db_null]
    } else {
	set insert_id $ad_conn(user_id)
    }

    set bind_vars [ad_tcl_list_list_to_ns_set [list \
	    [list session_id $session_id] \
	    [list user_id $insert_id] \
	    [list token $ad_conn(token)] \
	    [list secure_token $secure_token] \
	    [list browser_id $ad_conn(browser_id)] \
	    [list last_ip [ns_conn peeraddr]] \
	    [list last_hit [ns_time]]]]

    db_dml session_insert "
    insert into sec_sessions ([join [ad_ns_set_keys $bind_vars] ", "])
    values
    ([join [ad_ns_set_keys -colon $bind_vars] ", "])
    " -bind $bind_vars

    ns_set free $bind_vars

    # Update last_visit and second_to_last_visit
    set browser_id $ad_conn(browser_id)
    set current_time [ns_time]
    db_dml last_visit_rotate "declare begin sec_rotate_last_visit(:browser_id, :current_time); end;"
    db_release_unused_handles

    set ad_conn(session_id) $session_id

    if { [ad_secure_conn_p] } {
	set ad_conn(sec_validated) "secure"
    } else {
	set ad_conn(sec_validated) "insecure"
    }

    sec_generate_session_id_cookie

}

  
proc_doc sec_lookup_property { browser id module name } { Used as a helper procedure for util_memoize to look up a particular property from the database. Returns [list $property_value $secure_p]. } {
    set kind [ad_decode $browser "t" "browser" "session"]

    if {
	![db_0or1row property_lookup_sec "
	    select property_value, secure_p
	    from sec_${kind}_properties
	    where ${kind}_id = :id
	    and module = :module
	    and property_name = :name
	"]
    } {
	return ""
    }
    return [list $property_value $secure_p]
}

ad_proc ad_get_client_property {
    {
	-cache t
	-browser f
        -cache_only f
	-default ""
    }
    module
    name
} { Looks up a property for the current session, or for the browser. If $cache is true, will use the cached value if available. If $cache_only is true, will never incur a database hit (i.e., will only return a value if cached). If the property is secure, we must be on a validated session over SSL. } {
    
    global ad_conn

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
	return $default
    }
    set value [lindex $property 0]
    set secure_p [lindex $property 1]
    
    if { $secure_p != "f" && $ad_conn(sec_validated) != "secure" } {
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
} { 

    Sets a client (session- or browser-level) property. If $persistent
    is true, the new value will be written through to the database. If
    $deferred is true, the database write will be delayed until
    connection close (although calls to ad_get_client_property will
    still return the correct value immediately). If $secure is true,
    the property will not be retrievable except via a validated,
    secure (HTTPS) connection.   

} {
    global ad_conn
    
    if { $secure != "f" && $ad_conn(sec_validated) != "secure" } {
	error "Unable to set secure property in insecure or invalid session"
    }

    if { ![ad_validate_security_info -secure $secure] } {
 	return -code error "The user session didn't verify. Potential breach of security."
    }

    set kind    [ad_decode $browser "t" "browser" "session"]
    set kind_id [ad_get_${kind}_id]

    if { $persistent == "t" } {
        # Write to database - either defer, or write immediately. First delete the old
        # value if any; then insert the new one.

        set prop_delete_dml "
	delete from sec_${kind}_properties
	where  ${kind}_id    = $kind_id
	and    module        = '[db_quote $module]'
	and    property_name = '[db_quote $name]'
        "

        set prop_insert_dml "
	insert into sec_${kind}_properties
	  (${kind}_id, 
           module, 
           property_name, 
           property_value, 
           secure_p)
	values
	  ( $kind_id,
           '[db_quote $module]', 
           '[db_quote $name]', 
           empty_clob(), 
           '[db_quote $secure]')
	returning property_value into :1
        "

	# Process the delete / insert 

        if { $deferred == "t" } {
            ad_defer_dml db_dml sec_properties_delete $prop_delete_dml
            ad_defer_dml db_dml sec_properties_insert $prop_insert_dml -clobs [list $value]
        } else {

	    db_transaction {
		db_dml sec_properties_delete $prop_delete_dml
		db_dml sec_properties_insert $prop_insert_dml -clobs [list $value]
	    } 
        }
    }

    # Remember the new value, seeding the memoize cache with the proper value.
    util_memoize_seed [list sec_lookup_property $browser $kind_id $module $name] [list $value $secure]
}

proc_doc ad_secure_conn_p {} { Returns true if the connection [ns_conn] is secure (HTTPS), or false otherwise. } {
    return [regexp {^https:} [ns_conn location]]
}

proc_doc sec_generate_secure_token_cookie { secure_token } { Sets the ad_secure_token cookie. } {
    # Sanity check - make sure we're using HTTPS.
    if { [ad_secure_conn_p] } {
	ad_set_cookie -secure t "ad_secure_token" [ns_urlencode $secure_token]
    }
}

proc_doc sec_generate_session_id_cookie {} { Sets the ad_session_id cookie based on global variables. } {
    global ad_conn
    ad_set_cookie -replace t -max_age [sec_session_timeout] \
	    "ad_session_id" [ns_urlencode "$ad_conn(session_id),$ad_conn(user_id),$ad_conn(token),[ns_time]"]
}

proc_doc sec_clear_session_id_cookie {} { Clears the ad_session_id cookie. } {
    ad_set_cookie -replace t -max_age 0 "ad_session_id" ""
}

proc_doc sec_get_session_info { session_id } { Returns information for a session, in the form [list $user_id $token $secure_token $last_ip $last_hit]. } {

    if {
	![db_0or1row session_info_select {
	    select user_id, token, secure_token,
	           last_ip, last_hit from sec_sessions
	    where session_id = :session_id
	}]
    } {
	sec_log "No row in sec_sessions for session_id $session_id!"
	return
    }
    return [list $user_id $token $secure_token $last_ip $last_hit]
}

ad_proc ad_validate_security_info {
    { -secure f }
} { Validates the security info for the current connection, including session and user ID. If -secure t is specified, requires that the security info be secure to be considered valid. } {
    
    global ad_conn
     
    if { $ad_conn(sec_validated) == "secure" || ( $secure == "f" && $ad_conn(sec_validated) == "insecure" ) } {
	return 1
    }

    if { [catch {
	set security_info [util_memoize "sec_get_session_info $ad_conn(session_id)" \
			       [ad_parameter "SessionInfoCacheInterval" "" 600]]
    } errmsg] } {
	set security_info ""
	ns_log Notice "crapped out: $errmsg"
    }

    if { $security_info == "" } {
	ad_assign_session_id
	set security_info [util_memoize "sec_get_session_info $ad_conn(session_id)" \
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

    if { $last_hit + [sec_session_timeout] < [ns_time] || $user_id != $ad_conn(user_id) } {
	# Timeout. Fail, and clear the session ID cookie.
	sec_log "Timed out: clearing session ID cookie"
	sec_clear_session_id_cookie
	return 0
    }

    if { [string compare $token $ad_conn(token)] } {
	# The insecure token doesn't match. Fail, and clear the session ID cookie.
	sec_clear_session_id_cookie
	return 0
    }

    if { $secure == "f" } {
	# Passed with flying colors (for insecure validation).
	set ad_conn(sec_validated) "insecure"
    } else {
	if { ![ad_secure_conn_p] } {
	    # An insecure connection can't be securely validated.
	    return 0
	}

	if { [empty_string_p $secure_token] } {
	    # Secure token not yet assigned. Generate it; also regenerate insecure token.

	    set ad_conn(token) [sec_random_token]
	    set secure_token [sec_random_token]

	    set token $ad_conn(token)
	    set session_id $ad_conn(session_id)

	    db_dml sec_sessions_update {
                update sec_sessions
                set token = :token, secure_token = :secure_token
                where session_id = :session_id
	    }

	    util_memoize_seed "sec_get_session_info $ad_conn(session_id)" [list $user_id $ad_conn(token) $secure_token $last_ip $last_hit]

	    sec_generate_session_id_cookie
	    sec_generate_secure_token_cookie $secure_token
	} elseif { [string compare [ns_urldecode [ad_get_cookie "ad_secure_token"]] $secure_token] } {
	    # Secure token doesn't match. Nice try, sucka.
	    sec_clear_session_id_cookie
	    return 0
	}
	set ad_conn(sec_validated) "secure"
    }
    return 1
}

proc ad_verify_identity { conn args why } {
    set user_id [ad_verify_and_get_user_id]
    if {$user_id > 0} {
	# password checked out
	return filter_ok
    }
    if { [empty_string_p [ns_conn query]] } {
	set return_url [ns_conn url]
    } else {
	set return_url "[ns_conn url]?[ns_conn query]"
    }
    ad_returnredirect "/register/?[export_url_vars return_url]"
    return filter_return
}

proc_doc ad_get_user_id {} "Gets the user ID, without checking to see whether it is valid. This procedure shouldn't be used for any page where security is important." {
    global ad_conn
    return $ad_conn(user_id)
}

proc_doc ad_get_session_id {} "Gets the session ID, without checking to see whether it is valid. This procedure shouldn't be used for any page where security is important." {
    global ad_conn
    return $ad_conn(session_id)
}

proc_doc ad_get_browser_id {} "Gets the browser ID." {
    global ad_conn
    return $ad_conn(browser_id)
}

ad_proc ad_verify_and_get_user_id { { -secure f } } {

    Returns the current user's ID, verifying its validity (or returning 0 if unable to do so).

} {

    if { ![ad_validate_security_info -secure $secure] } {
	return 0
    } else {
        set user_id [ad_get_user_id]
	# check if the user is registered
	if { $user_id==0 } { 
	    # is user is not registered return 0
	    return 0
	}

	set user_state [db_string find_user_state "select user_state from users where user_id = :user_id"]

	switch $user_state {
	    "authorized" {  }
	    # just move on
	    "banned" { 
		ad_returnredirect "/register/banned-user.tcl?user_id=$user_id" 
		ad_script_abort
	    }
	    "deleted" {  
		ad_returnredirect "/register/deleted-user.tcl?user_id=$user_id" 
		ad_script_abort
	    }
	    "need_email_verification_and_admin_approv" {
		ad_returnredirect "/register/awaiting-email-verification.tcl?user_id=$user_id"
		ad_script_abort
	    }
	    "need_admin_approv" { 
		ad_returnredirect "/register/awaiting-approval.tcl?user_id=$user_id"
		ad_script_abort
	    }
	    "need_email_verification" {
		ad_returnredirect "/register/awaiting-email-verification.tcl?user_id=$user_id"
		ad_script_abort
	    }
	    "rejected" {
		ad_returnredirect "/register/awaiting-approval.tcl?user_id=$user_id"
		ad_script_abort
	    }
	    default {
		ns_log Warning "Problem with registration state machine on user-login.tcl"
		ad_return_error "Problem with login" "There was a problem authenticating the account: $user_id. Most likely, the database contains users with no user_state."
		ad_script_abort
	    }
	}
    }
    return $user_id
}

ad_proc ad_verify_and_get_session_id { { -secure f } } {

    Returns the current session's ID, verifying its validity (or returning 0 if unable to do so).

} {
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

proc_doc ad_redirect_for_registration {} {
    
    Redirects user to /register/index to require the user to
    register. When registration is complete, the user will be returned
    to the current location.  All variables in ns_getform (both posts and
    gets) will be maintained.

} {
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
    ad_returnredirect "/register/?return_url=[ns_urlencode [ns_conn url]$url_args]"
    return
}

proc_doc ad_maybe_redirect_for_registration {} {

    Checks to see if a user is logged in.  If not, redirects to
    /register/index to require the user to register. When registration
    is complete, the user will return to the current location.  All
    variables in ns_getform (both posts and gets) will be maintained.
    Note that this will return out of its caller so that the caller need
    not explicitly call "return". Returns the user id if login was
    succesful.

} {
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

proc ad_filter_restricted_content_sections {} {
    # let's also bounce them out of private content sections 

    db_foreach content_sections_filter {
	select section_url_stub 
	from content_sections
	where scope='public'
	and requires_registration_p = 't'
    } {
	ns_log Notice "Going to filter out access to $section_url_stub, marked as requiring registration in the content_sections table"
	ad_register_filter preauth HEAD "${section_url_stub}*" ad_verify_identity
	ad_register_filter preauth GET "${section_url_stub}*" ad_verify_identity
	ad_register_filter preauth POST "${section_url_stub}*" ad_verify_identity
    }
}

proc_doc ad_restrict_entire_server_to_registered_users {conn args why} "A preauth filter that will halt service of any page if the user is unregistered, except the site index page and stuff underneath /register" {
    if {![string match "/index.tcl" [ns_conn url]] && ![string match "/" [ns_conn url]] && ![string match "/register/*" [ns_conn url]] && ![string match "/SYSTEM/*" [ns_conn url]] && ![string match "/cookie-chain*" [ns_conn url]] && ![string match "/user_please_login.tcl" [ns_conn url]]} {
	# not one of the magic acceptable URLs
	set user_id [ad_verify_and_get_user_id]
	if {$user_id == 0} {
	    ad_returnredirect "/register/?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
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

#
# The filter below will block requests containing character sequences that
# could be used to modify insecurely coded SQL queries in our Tcl scripts,
# like " or 1=1" or "1 union select ...".
#
# Written by branimir@arsdigita.com and carsten@arsdigita.com on July 2, 2000.
#

# michael@arsdigita.com: A better name for this proc would be
# "ad_block_sql_fragment_form_data", since "form data" is the
# official term for query string (URL) variables and form input
# variables.
#
proc_doc ad_block_sql_urls {conn args why} {

    A filter that detect attempts to smuggle in SQL code through form data
    variables

} {
    set form [ns_getform]
    if [empty_string_p $form] { return filter_ok }

    # Check each form data variable to see if it contains malicious
    # user input that we don't want to interpolate into our SQL
    # statements.
    #
    # We do this by scanning the variable for suspicious phrases; at
    # this time, the phrases we look for are: UNION, UNION ALL, and
    # OR.
    #
    # If one of these phrases is found, we construct a test SQL query
    # that incorporates the variable into its WHERE clause and ask
    # the database to parse it. If the query does parse successfully,
    # then we know that the suspicious user input would result in a
    # executing SQL that we didn't write, so we abort processing this
    # HTTP request.
    #
    set n_form_vars [ns_set size $form]
    for { set i 0 } { $i < $n_form_vars } { incr i } {
        set key [ns_set key $form $i]
        set value [ns_set value $form $i]

	# michael@arsdigita.com:
	#
	# Removed 4000-character length check, because that allowed
	# malicious users to smuggle SQL fragments greater than 4000
	# characters in length.
	#
        if {
	    [regexp -nocase {[^a-z_]or[^a-z0-9_]} $value] ||
	    [regexp -nocase {union([^a-z0-9_].*all)?[^a-z0-9_].*select} $value]
	} {
	    # Looks like the user has added "union [all] select" to
	    # the variable, # or is trying to modify the WHERE clause
	    # by adding "or ...".
	    #
            # Let's see if Oracle would accept this variables as part
	    # of a typical WHERE clause, either as string or integer.
	    #
	    # michael@arsdigita.com: Should we grab a handle once
	    # outside of the loop?
	    #
            set parse_result_integer [db_string sql_test_1 "select test_sql('select 1 from dual where 1=[DoubleApos $value]') from dual"]

            if { [string first "'" $value] != -1 } {
		#
		# The form variable contains at least one single
		# quote. This can be a problem in the case that
		# the programmer forgot to QQ the variable before
		# interpolation into SQL, because the variable
		# could contain a single quote to terminate the
		# criterion and then smuggled SQL after that, e.g.:
		#
		#   set foo "' or 'a' = 'a"
		#
		#   db_dml "delete from bar where foo = '$foo'"
		#
		# which would be processed as:
		#
		#   delete from bar where foo = '' or 'a' = 'a'
		#
		# resulting in the effective truncation of the bar
		# table.
		#
                set parse_result_string [db_string sql_test_2 "select test_sql('select 1 from dual where 1=[DoubleApos "'$value'"]') from dual"]
            } else {
                set parse_result_string 1
            }

            if {
		$parse_result_integer == 0 ||
		$parse_result_integer == -904  ||
		$parse_result_integer == -1789 ||
		$parse_result_string == 0 ||
		$parse_result_string == -904 ||
		$parse_result_string == -1789
	    } {
                # Code -904 means "invalid column", -1789 means
		# "incorrect number of result columns". We treat this
		# the same as 0 (no error) because the above statement
		# just selects from dual and 904 or 1789 only occur
		# after the parser has validated that the query syntax
		# is valid.

                ns_log Error "ad_block_sql_urls: Suspicious request from [ns_conn peeraddr]. Parameter $key contains code that looks like part of a valid SQL WHERE clause: [ns_conn url]?[ns_conn query]"

		# michael@arsdigita.com: Maybe we should just return a
		# 501 error.
		#
                ad_return_error "Suspicious Request" "Parameter $key looks like it contains SQL code. For security reasons, the system won't accept your request."

                return filter_return
            }
        }
    }

    return filter_ok
}

proc_doc ad_set_typed_form_variable_filter {url_pattern args} {
    <pre>
    #
    # Register special rules for form variables.
    #
    # Example:
    #
    #    ad_set_typed_form_variable_filter /my_module/* {a_id number} {b_id word} {*_id integer}
    #
    # For all pages under /my_module, set_form_variables would set 
    # $a_id only if it was number, and $b_id only if it was a 'word' 
    # (a string that contains only letters, numbers, dashes, and 
    # underscores), and all other variables that match the pattern
    # *_id would be set only if they were integers.
    #
    # Variables not listed have no restrictions on them.
    #
    # By default, the three supported datatypes are 'integer', 'number',
    # and 'word', although you can add your own type by creating
    # functions named ad_var_type_check_${type_name}_p which should
    # return 1 if the value is a valid $type_name, or 0 otherwise.
    #
    # There's also a special datatype named 'nocheck', which will
    # return success regardless of the value. (See the docs for 
    # ad_var_type_check_${type_name}_p to see how this might be
    # useful.)
    #
    # The default data_type is 'integer', which allows you shorten the
    # command above to:
    #
    #    ad_set_typed_form_variable_filter /my_module/* a_id {b_id word}
    #
    </pre>
} {
    ad_register_filter postauth GET  $url_pattern ad_set_typed_form_variables $args
    ad_register_filter postauth POST $url_pattern ad_set_typed_form_variables $args
}

proc ad_set_typed_form_variables {conn args why} {

    global ad_typed_form_variables

    eval lappend ad_typed_form_variables [lindex $args 0]

    return filter_ok
}

#
# All the ad_var_type_check* procs get called from 
# check_for_form_variable_naughtiness. Read the documentation
# for ad_set_typed_form_variable_filter for more details.

proc_doc ad_var_type_check_integer_p {value} {
    <pre>
    #
    # return 1 if $value is an integer, 0 otherwise.
    #
    <pre>
} {

    if [regexp {[^0-9]} $value] {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_safefilename_p {value} {
    <pre>
    #
    # return 0 if the file contains ".."
    #
    <pre>
} {

    if [string match *..* $value] {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_dirname_p {value} {
    <pre>
    #
    # return 0 if $value contains a / or \, 1 otherwise.
    #
    <pre>
} {

    if [regexp {[/\\]} $value] {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_number_p {value} {
    <pre>
    #
    # return 1 if $value is a valid number
    #
    <pre>
} {
    if [catch {expr 1.0 * $value}] {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_word_p {value} {
    <pre>
    #
    # return 1 if $value contains only letters, numbers, dashes, 
    # and underscores, otherwise returns 0.
    #
    </pre>
} {

    if [regexp {[^-A-Za-z0-9_]} $value] {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_nocheck_p {{value ""}} {
    <pre>
    #
    # return 1 regardless of the value. This useful if you want to 
    # set a filter over the entire site, then create a few exceptions.
    #
    # For example:
    #
    #   ad_set_typed_form_variable_filter /my-dangerous-page.tcl {user_id nocheck}
    #   ad_set_typed_form_variable_filter /*.tcl user_id
    #
    </pre>
} {
    return 1
}

proc_doc ad_var_type_check_noquote_p {value} {
    <pre>
    #
    # return 1 if $value contains any single-quotes
    #
    <pre>
} {

    if [string match *'* $value] {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_integerlist_p {value} {
    <pre>
    #
    # return 1 if list contains only numbers, spaces, and commas.
    # Example '5, 3, 1'. Note: it doesn't allow negative numbers,
    # because that could let people sneak in numbers that get
    # treated like math expressions like '1, 5-2'
    #
    #
    <pre>
} {

    if [regexp {[^ 0-9,]} $value] {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_fail_p {value} {
    <pre>
    #
    # A check that always returns 0. Useful if you want to disable all access
    # to a page.
    #
    <pre>
} {
    return 0
}

proc_doc ad_var_type_check_third_urlv_integer_p {{args ""}} {
    <pre>
    #
    # Returns 1 if the third path element in the URL is integer.
    #
    <pre>
} {

    set third_url_element [lindex [ns_conn urlv] 3]

    if [regexp {[^0-9]} $third_url_element] {
        return 0
    } else {
        return 1
    }
}
