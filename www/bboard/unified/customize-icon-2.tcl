# /www/bboard/unified/customize-icon-2.tcl
ad_page_contract {
    Adds a custom icon for a topi

    @param topic_id the ID of the topic to add
    @param icon_id the ID of the icon to add

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id customize-icon-2.tcl,v 1.1.4.4 2000/08/06 21:56:52 kevin Exp
} {
    topic_id:integer,notnull
    icon_id:integer,notnull
}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

db_dml topic_update "
UPDATE bboard_unified
SET    icon_id  = :icon_id
WHERE  user_id  = :user_id
AND    topic_id = :topic_id
"

db_release_unused_handles

ad_returnredirect personalize?