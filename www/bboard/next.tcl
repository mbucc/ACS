# /www/bboard/next.tcl
ad_page_contract {
    Goes to the next posting.

    @param msg_id the current message
    @param topic_id the ID of the topic being looked at

    @author ?
    @creation-date ?
    @cvs-id
} {
    msg_id
    topic_id:integer
    topic
}

# -----------------------------------------------------------------------------

set do_returnredirect 1

db_foreach later_postings "
select msg_id as next_msg_id, sort_key
from bboard 
where sort_key > (select sort_key from bboard where msg_id = :msg_id)
and topic_id = :topic_id
order by sort_key" {

    # get one row
    # we don't want the rest of the rows so we

    break

    # boy, this is pretty sick

} if_no_rows {

    # no msg to return

    doc_return  200 text/html "[ad_header "" "End of BBoard"]
    
    <h3>No Next Message</h3>
    
    You've read the last message in the <a target=_top href=\"main-frame?[export_url_vars topic topic_id]\">$topic</a> BBoard.
    
    [bboard_footer]
    "

    set do_returnredirect 0
    return
}

if { $do_returnredirect } {
    ad_returnredirect "fetch-msg.tcl?msg_id=$next_msg_id"
}
