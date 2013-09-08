# /www/admin/bboard/unified/toggle-p.tcl
ad_page_contract {
    sets the specified topics to be default forums

    @param topic_ids the list of topics
    
    @author LuisRodriguez@photo.net
    @cvs-id toggle-p.tcl,v 1.1.4.4 2000/08/06 21:56:23 kevin Exp
} {
    topic_ids:multiple,integer
}

# -----------------------------------------------------------------------------

ad_maybe_redirect_for_registration

page_validation {
    if { [llength $topic_ids] == 0 } {
	error " You must select at least one default Forum"
    }
}

db_transaction {

    db_dml set_default_f "
    UPDATE bboard_topics
    SET default_topic_p = 'f'
    "

    foreach one_topic_id $topic_ids {
	db_dml set_default_t "
	UPDATE bboard_topics
	SET default_topic_p = 't'
	WHERE topic_id = :one_topic_id
	"
    }
}

db_release_unused_handles
ad_returnredirect index
