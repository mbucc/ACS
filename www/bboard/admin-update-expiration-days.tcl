# /www/bboard/admin-update-expiration-days.tcl
ad_page_contract {
    changes the expiration days for a topic

    @cvs-id admin-update-expiration-days.tcl,v 3.2.2.4 2000/07/21 03:58:39 ron Exp
} {
    msg_id:notnull
    expiration_days
}

# -----------------------------------------------------------------------------

db_1row topic_id "
select topic_id from bboard where msg_id = :msg_id"
 
if {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}



# we're authorized 

if { $expiration_days == "" } { 
    set expiration_days [db_null] 
}

db_dml bboard_update "
update bboard set expiration_days = :expiration_days 
where msg_id = :msg_id"

ad_returnredirect "admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id"
