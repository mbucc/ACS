ad_page_contract {
    @author tea
    @creation-date 10/22/1998
    @param cookie_name
    @param cookie_value
    @param final_page
    @param expire_state
    @cvs-id cookie-chain-2.tcl,v 3.1.6.2 2000/07/21 03:55:54 ron Exp
} {
    {cookie_name:notnull}
    {cookie_value:notnull}
    {final_page:notnull}
    {expire_state:notnull}
}

switch $expire_state {
    s   { set expire_clause "" }
    p   { set expire_clause "expires=Fri, 01-Jan-2010 01:00:00 GMT" }
    e   { set expire_clause "expires=Mon, 01-Jan-1990 01:00:00 GMT" }
    default { ns_log Error "cookie-chain-2.tcl called with unknown expire_state: \"$expire_state\""
              # let's try to salvage something for the user
              set expire_clause ""
            }
}

ns_set put [ns_conn outputheaders] "Set-Cookie" "$cookie_name=$cookie_value; path=/; $expire_clause"

ad_returnredirect $final_page
