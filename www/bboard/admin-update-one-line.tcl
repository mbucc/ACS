# /www/bboard/admin-update-one-line.tcl
ad_page_contract {
    changes the subject line for a message

    @cvs-id admin-update-one-line.tcl,v 3.1.6.3 2000/07/21 03:58:39 ron Exp
} {
    msg_id:notnull
    oneline:notnull
}

# -----------------------------------------------------------------------------

db_1row topic_id "
select unique topic_id from bboard where msg_id = :msg_id"

bboard_get_topic_info

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

# we're authorized 

db_dml bboard_update "
update bboard set one_line = :one_line where msg_id = :msg_id"

ad_returnredirect "admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id"
