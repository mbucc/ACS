# /www/admin/bboard/unified/customize-icon-2.tcl
ad_page_contract {
    Processed the icon change

    @param icon_id the ID of the icon being changed
    @param topic_id the ID of the bboard topic

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id customize-icon-2.tcl,v 1.1.4.4 2000/08/06 21:56:23 kevin Exp
} {
    icon_id:integer,notnull
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------

ad_maybe_redirect_for_registration

db_dml icon_update "
UPDATE bboard_topics
SET icon_id = :icon_id
WHERE topic_id = :topic_id
"

db_release_unused_handles

ad_returnredirect index?