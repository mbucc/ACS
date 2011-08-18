# $Id: cookie-chain-1.tcl,v 3.0.4.1 2000/04/28 15:08:20 carsten Exp $
# 1998/10/22 tea
# updated by philg 10/25/98
set_form_variables

#Requires:
#cookie_name, cookie_value, final_page, expire_state

switch $expire_state {
    s   { set expire_clause "" }
    p   { set expire_clause "expires=Fri, 01-Jan-2010 01:00:00 GMT" }
    e   { set expire_clause "expires=Mon, 01-Jan-1990 01:00:00 GMT" }
    default { ns_log Error "cookie-chain-1.tcl called with unknown expire_state: \"$expire_state\""
              # let's try to salvage something for the user
              set expire_clause ""
            }
}

ns_set put [ns_conn outputheaders] "Set-Cookie" "$cookie_name=$cookie_value; path=/; $expire_clause"

ad_returnredirect "http://[ad_cookie_chain_second_host_name]/cookie-chain-2.tcl?[export_url_vars cookie_name cookie_value final_page expire_state]"

