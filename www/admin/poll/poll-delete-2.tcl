# /admin/poll/poll-delete-2.tcl 

ad_page_contract {
    Remove a poll from the database, including votes.

    @param poll_id the ID of the poll to be deleted

    @cvs-id poll-delete-2.tcl,v 3.2.2.4 2000/07/21 03:57:51 ron Exp
} {
    poll_id:notnull,naturalnum
}



db_transaction {

    db_dml delete_user_choices "delete from poll_user_choices where poll_id = :poll_id"
    db_dml delete_poll_choices "delete from poll_choices where poll_id = :poll_id"
    db_dml delete_poll "delete from polls where poll_id = :poll_id"

}

db_release_unused_handles

ad_returnredirect ""

