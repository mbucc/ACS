# /www/bboard/unified/add-topic-to-view.tcl
ad_page_contract {
    Add a topic to a user's view

    @param topic_id the ID of the topic to add

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id add-topic-to-view.tcl,v 1.1.4.4 2000/08/06 21:56:52 kevin Exp
} {
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

set topic_in_view [db_string topic_in_view "
SELECT count(*)
FROM bboard_unified
WHERE user_id = :user_id
  AND topic_id = :topic_id
"]

if { $topic_in_view == 0 } {

    db_dml topic_insert "
    INSERT INTO bboard_unified
    (user_id, topic_id)
    VALUES
    (:user_id, :topic_id])"
}

ad_returnredirect personalize?