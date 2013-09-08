ad_page_contract {
    Changes the interest level.

    @cvs-id admin-update-interest-level.tcl,v 3.3.2.3 2000/07/21 05:51:57 bquinn Exp
} {
    msg_id:notnull
    interest_level:integer,notnull
}



# -----------------------------------------------------------------------------

db_1row topic_id "
select unique topic_id from bboard where msg_id = :msg_id"
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

# we're authorized, now check the interest level
page_validation {
    if {$interest_level < 0 || $interest_level > 10} {
	error "Interest Level given did not match the requirements. It should be a number between 0 and 10."
    }
}

db_dml bboard_update "
update bboard set interest_level = :interest_level where msg_id = :msg_id"

ad_returnredirect "admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id"
