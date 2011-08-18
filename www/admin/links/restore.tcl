# $Id: restore.tcl,v 3.0.4.1 2000/04/28 15:09:09 carsten Exp $
# restore.tcl
# 
# by philg@mit.edu on July 18, 1999
# 
# restores a link to "live" status if it has been erroneously kicked
# into "dead" or "removed" for whatever reason

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# we know who the administrator is

set_the_usual_form_variables

# page_id, url

set db [ns_db gethandle]

ns_db dml $db "update links 
set status = 'live'
where page_id = $page_id
and url = '$QQurl'"

ad_returnredirect "one-page.tcl?[export_url_vars page_id]"
