# /www/bboard/unified/reset-personalization.tcl
ad_page_contract {
    resets the users personalizations to the default

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id reset-personalization.tcl,v 1.1.4.4 2000/08/06 21:56:53 kevin Exp
} {
}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

db_transaction {

    db_dml personalization_delete "
    DELETE FROM bboard_unified
    WHERE user_id = :user_id"

    db_dml personalization_default "
    INSERT INTO bboard_unified
    (user_id, topic_id, default_topic_p, color, icon_id)
    SELECT :user_id, topic_id, default_topic_p, color, icon_id
    FROM bboard_topics"

}

db_release_unused_handles

ad_returnredirect personalize?
