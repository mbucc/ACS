# /www/admin/bboard/toggle-active-p.tcl
ad_page_contract {
    Toggles whether a topic is active or not

    @param topic the topic being modified
} {
    topic
}

# -----------------------------------------------------------------------------

db_dml topic_toggle "
update bboard_topics 
set active_p = logical_negation(active_p) 
where topic= :topic"

ad_returnredirect "index.tcl"
