# /www/webmail/preferences-2.tcl

ad_page_contract {
    Sets user preferences.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2000-06-01
    @cvs-id preferences-2.tcl,v 1.4.2.4 2000/08/13 23:18:53 mbryzek Exp
} {
    { refresh_seconds:integer 0 } 
    { return_url index }
}


# Set the client refresh rate 

if { $refresh_seconds < 0 } {
    set refresh_seconds 0
} elseif { $refresh_seconds > 0 && $refresh_seconds < 60 } {
    # Don't let people refresh more often than once a minute
    set refresh_seconds 60
}
ad_set_client_property -browser t "webmail" "seconds_between_refresh" $refresh_seconds

ad_returnredirect $return_url
