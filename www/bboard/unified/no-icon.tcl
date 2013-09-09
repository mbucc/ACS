# /www/bboard/unified/no-icon.tcl
ad_page_contract {
    remove the custom icon for a section

    @param topic_id the ID for the bboard topic
    @param icon_id the ID for the icon

    @author LuisRodriguez@photo.net
    @creation_date May 2000
    @cvs-id no-icon.tcl,v 1.1.4.4 2000/08/06 21:56:52 kevin Exp
} {
    topic_id:integer,notnull
    icon_id:integer,notnull
}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

db_dml null_icon "
UPDATE bboard_unified
SET icon_id = NULL
WHERE user_id = :user_id
AND   topic_id = :topic_id
"

db_release_unused_handles

ad_returnredirect personalize?