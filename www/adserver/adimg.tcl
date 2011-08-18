# $Id: adimg.tcl,v 3.0.4.1 2000/04/28 15:09:39 carsten Exp $
# adimg.tcl
#
# at this point mostly by philg@mit.edu 
# last edited November 24, 1999 to address a concurrency problem 
# 
# this page 
#   tries to find an image file to serve to the user
#   serves it
#   closes the TCP connection to the user
#   while this thread is still alive, logs the ad display
#

set_the_usual_form_variables 0

# adv_key, maybe suppress_logging_p

set display_default_banner_p 0

if { ![info exists adv_key] || $adv_key == "" } {
    set display_default_banner_p 1
} else {
    set db [ns_db gethandle]

    set selection [ns_db 0or1row $db "SELECT adv_filename as ad_filename_stub, local_image_p
FROM advs 
WHERE adv_key = '$QQadv_key'"]

    if { $selection == "" } {
	set display_default_banner_p 1
    } else {
	set_variables_after_query
    }
}

if { $display_default_banner_p } {
    append default_banner_filename [ns_info pageroot] [ad_parameter DefaultAd adserver]
    if [file isfile $default_banner_filename] {
	ns_returnfile 200 [ns_guesstype $default_banner_filename] $default_banner_filename
    } else {
	# we're really in bad shape; no default file exists and 
	# we don't have an adv_key
	ns_log Error "adimg.tcl didn't get an ad key AND no default file exists"
	ad_notify_host_administrator "define a default ad!" "Define a default banner ad in [ad_system_name]; someone is requesting ads without an adv_key"
    }
    return
}

if {$local_image_p == "t"} {
    # image lives in the local filesystem
    append ad_filename [ns_info pageroot] $ad_filename_stub
} else {
    # image lives on a remote server, so adv_filename is really a URL.
    set ad_filename $ad_filename_stub
}


# Should we check for the existence of the ad on the remote host?  For now, we don't
if { $ad_filename_stub == "" || ($local_image_p == "t" && ![file isfile $ad_filename]) } {
    ns_log Error "Didn't find ad: $ad_filename"
    append default_banner_filename [ns_info pageroot] [ad_parameter DefaultAd adserver]
    if [file isfile $default_banner_filename] {
	ns_returnfile 200 [ns_guesstype $default_banner_filename] $default_banner_filename
    } else {
	# we're really in bad shape; no row exists and 
	# we don't have an adv_key
	ns_log Error "adimg.tcl didn't find an ad matching \"$adv_key\" AND no default file exists"
	ad_notify_host_administrator "define a default ad!" "Define a default banner ad in [ad_system_name]; someone is requesting ads with an invalid adv_key of \"$adv_key\""
    }
    return
}

if {$local_image_p == "t"} {
    # return the file

    # the no-cache stuff ensures that Netscape browser users never get a
    # cached IMG with a new target

    ns_returnfile 200 "[ns_guesstype $ad_filename]\nPragma: no-cache" $ad_filename
} else {
    # let the remote server provide the image
    ad_returnredirect $ad_filename
}

if { [info exists suppress_logging_p] && $suppress_logging_p == 1 } {
    return
}

# we've returned to the user but let's keep this thread alive to log

ns_conn close

ns_db dml $db "update adv_log 
set display_count = display_count + 1 
where adv_key='$QQadv_key'
and entry_date = trunc(sysdate)"

set n_rows [ns_ora resultrows $db]

if { $n_rows == 0 } {
    # there wasn't a row in the database; we can't just do the obvious insert
    # because another thread might be executing concurrently
    ns_db dml $db "insert into adv_log 
(adv_key, entry_date, display_count) 
select '$QQadv_key', trunc(sysdate), 1
from dual
where 0 = (select count(*) 
           from adv_log
           where adv_key='$QQadv_key'
           and entry_date = trunc(sysdate))"
}

