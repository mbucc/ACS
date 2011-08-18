# Target page for redirecting results of a site wide search query.

set_the_usual_form_variables
# msg_id

set db [ns_db gethandle]
if { $db == "" } {
    ad_return_error_page
    return
}

set selection [ns_db 1row $db "select presentation_type, sort_key, bboard_topics.topic_id, bboard_topics.topic
from bboard, bboard_topics
where bboard.msg_id = '$msg_id'
and bboard_topics.topic_id = bboard.topic_id"]

set_variables_after_query

if { [string first "." $sort_key] == -1 } {
    # there is no period in the sort key so this is the start of a thread
    set thread_start_msg_id $sort_key
} else {
    # strip off the stuff before the period
    regexp {(.*)\..*} $sort_key match thread_start_msg_id
}

ad_returnredirect [bboard_msg_url $presentation_type $thread_start_msg_id $topic_id $topic]
