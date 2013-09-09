#/www/cookie-chain.tcl
ad_page_contract {

    @author tea
    @creation-date 10/22/1998
    @param cookie_name notnull
    @param cookie_value notnull
    @param final_page notnull
    @param expire_state notnull
    @cvs-id cookie-chain.tcl,v 3.1.6.2 2000/07/21 03:55:54 ron Exp
} {
    {cookie_name:notnull}
    {cookie_value:notnull}
    {final_page:notnull}
    {expire_state "s"}
}

# cookie_name - name of cookie
# cookie_value - value of cookie
# final_page - url of the page you want to the user to end on (ie /, or
# index.tcl)
# expire_state -
#     p for a persistent cookie
#     s for a session cookie (default)
#     e to expire the cookie


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
