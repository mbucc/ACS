# /www/bboard/redirect-for-sws.tcl
ad_page_contract {
    Target page for redirecting results of a site wide search query.

    @param msg_id a bboard message ID

    @cvs-id redirect-for-sws.tcl,v 3.3.2.3 2000/07/21 03:58:50 ron Exp
} {
    {msg_id}
}

# -----------------------------------------------------------------------------

page_validation {
    bboard_validate_msg_id $msg_id
}

db_1row topic "
select presentation_type, sort_key, 
       bboard_topics.topic_id, bboard_topics.topic
from   bboard, bboard_topics
where  bboard.msg_id = :msg_id
and    bboard_topics.topic_id = bboard.topic_id"


if { [string first "." $sort_key] == -1 } {
    # there is no period in the sort key so this is the start of a thread
    set thread_start_msg_id $sort_key
} else {
    # strip off the stuff before the period
    regexp {(.*)\..*} $sort_key match thread_start_msg_id
}

ad_returnredirect [bboard_msg_url $presentation_type $thread_start_msg_id $topic_id $topic]
