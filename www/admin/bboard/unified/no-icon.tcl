# /www/admin/bboard/unified/no-icon.tcl
ad_page_contract {
    Removes the icon from a topic

    @param topic_id the ID of the bboard topic
    @param icon_id the ID of the existing icon (not actually used)

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id no-icon.tcl,v 1.1.4.4 2000/08/06 21:56:23 kevin Exp
} {
    topic_id:integer,notnull
    icon_id:integer,notnull
}

# -----------------------------------------------------------------------------

ad_maybe_redirect_for_registration

db_dml icon_remove "
UPDATE bboard_topics
SET icon_id = NULL
WHERE topic_id = :topic_id
"

db_release_unused_handles

ad_returnredirect index?