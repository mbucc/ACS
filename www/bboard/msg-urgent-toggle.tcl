# /www/bboard/msg-urgent-toggle.tcl
ad_page_contract {
    toggles the urgent status of a message

    @param msg_id the message to alter
    @param return_rul where to do when done

    @cvs-id msg-urgent-toggle.tcl,v 3.2.2.3 2000/07/21 03:58:44 ron Exp
} {
    msg_id:notnull
    return_url
}

# -----------------------------------------------------------------------------

page_validation {
    bboard_validate_msg_id $msg_id
}

set user_id [ad_verify_and_get_user_id]

db_dml toggle "
update bboard set urgent_p = logical_negation(urgent_p) 
where msg_id = :msg_id  
and bboard.user_id = :user_id"

ad_returnredirect $return_url
