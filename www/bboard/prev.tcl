# /www/bboard/prev.tcl
ad_page_contract {
    Sends the user to the previous message

    @param topic_id the ID of the topic being read
    @param msg_id the ID current message

    @author ?
    @creation-date ?
    @cvs-id prev.tcl,v 3.2.6.5 2000/10/27 21:56:53 bcalef Exp
} {
    topic_id:integer
    msg_id
    topic
}

# -----------------------------------------------------------------------------

set do_returnredirect 1

db_foreach earlier_messages "
select msg_id, sort_key
from bboard 
where sort_key < (select sort_key from bboard where msg_id = :msg_id)
and topic_id = :topic_id
order by sort_key desc" {

    # get values for one row
    # we don't want the rest of the rows

    break

} if_no_rows {

    # no msg to return

    doc_return  200 text/html "[ad_header "" "No Previous Message"]

<h3>No Previous Message</h3>

You've read the first message in the  <a target=_top href=\"main-frame?[export_url_vars topic topic_id]\">$topic</a> BBoard.

[bboard_footer]
"

    set do_returnredirect 0
    return

}

if { $do_returnredirect } {
    ad_returnredirect "fetch-msg.tcl?msg_id=$msg_id"
}

