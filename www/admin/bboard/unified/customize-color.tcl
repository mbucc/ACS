# /www/admin/bboard/unified/customize-color.tcl
ad_page_contract {
    Changes the color associated with a bboard topic

    @param topic_id the ID of the bboard topic
    @param color the hex color specification

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id customize-color.tcl,v 1.2.2.4 2000/08/06 21:56:23 kevin Exp
} {
    topic_id:integer,notnull
    color:trim,notnull
}

# -----------------------------------------------------------------------------

ad_maybe_redirect_for_registration

page_validation {
    if { ![regexp "#(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])" $color match] } {
	error "Color must be in form #XXXXXX where X is a hexadecimal character.  You entered: $color"
    }
}

db_dml color_update "
UPDATE bboard_topics
SET color = :color
WHERE topic_id = :topic_id
"

db_release_unused_handles

ad_returnredirect index?