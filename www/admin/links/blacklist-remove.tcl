# $Id: blacklist-remove.tcl,v 3.0.4.1 2000/04/28 15:09:09 carsten Exp $
set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

set_the_usual_form_variables

# rowid

set db [ns_db gethandle]

ns_db dml $db "delete from link_kill_patterns where rowid='$QQrowid'"

ad_returnredirect blacklist-all.tcl
