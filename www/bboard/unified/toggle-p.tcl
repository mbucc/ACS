# /www/bboard/unified/toggle-active-p.tcl
ad_page_contract {
    toggles default topics

    @param topic_ids list of topics to set as defaults

    @author raj@alum.mit.edu
    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id toggle-p.tcl,v 1.1.4.4 2000/08/06 21:56:53 kevin Exp
} {
    topic_ids:multiple
}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

db_transaction {

    db_dml set_default_f "
    UPDATE bboard_unified
    SET default_topic_p = 'f'
    WHERE user_id = :user_id"

    foreach one_topic_id $topic_ids {
	db_dml set_default_t "
	UPDATE bboard_unified
	SET default_topic_p = 't'
	WHERE topic_id = :one_topic_id
	AND user_id=Duser_id"
    }

}

ad_returnredirect personalize?

