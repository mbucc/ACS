# $Id: cookie-chain.tcl,v 3.0.4.1 2000/04/28 15:08:21 carsten Exp $
# 1998/10/22 tea
# fixed by philg 10/25/98
set_form_variables

#Requires:
#cookie_name, cookie_value, final_page, expire_state

# cookie_name - name of cookie
# cookie_value - value of cookie
# final_page - url of the page you want to the user to end on (ie /, or
# index.tcl)
# expire_state -
#     p for a persistent cookie
#     s for a session cookie (default)
#     e to expire the cookie

if ![info exists expire_state] {
    set expire_state "s"
}

switch $expire_state {
    s   { set expire_clause "" }
    p   { set expire_clause "expires=Fri, 01-Jan-2010 01:00:00 GMT" }
    e   { set expire_clause "expires=Mon, 01-Jan-1990 01:00:00 GMT" }
    default { ns_log Error "cookie-chain.tcl called with unknown expire_state: \"$expire_state\""
              # let's try to salvage something for the user
              set expire_clause ""
            }
}

# we're going to assume that most of the time people 
# leave cookie_value empty when they are expiring a cookie

if ![info exists cookie_value] {
    set cookie_value "expired"
}

if [ad_need_cookie_chain_p] {
    if { [ns_conn driver] == "nsssl" } {
	set protocol "https"
    } else {
	set protocol "http"
    }
    ad_returnredirect "$protocol://[ad_cookie_chain_first_host_name]/cookie-chain-1.tcl?[export_url_vars cookie_name cookie_value final_page expire_state]"
} else {
    ns_set put [ns_conn outputheaders] "Set-Cookie" "$cookie_name=$cookie_value; path=/; $expire_clause"
    ad_returnredirect $final_page
}
