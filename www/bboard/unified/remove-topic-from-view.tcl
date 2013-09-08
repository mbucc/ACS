# /www/bboard/unified/remove-topic-from-view.tcl
ad_page_contract {
    Removes a topic from the users view

    @param topic_id the ID of the topic to remove

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id remove-topic-from-view.tcl,v 1.1.4.4 2000/08/06 21:56:53 kevin Exp
} {
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

db_dml unused "
DELETE FROM bboard_unified
WHERE user_id = :the_user_id
  AND topic_id = :topic_id"

ad_returnredirect personalize?