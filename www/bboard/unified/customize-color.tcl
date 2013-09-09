# /www/bboard/unified/customize-color.tcl
ad_page_contract {
    Set a custom color for a topic

    @param topic_id the ID of the bboard topic
    @param color the color to use

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id customize-color.tcl,v 1.1.4.4 2000/08/06 21:56:52 kevin Exp
} {
    topic_id:integer,notnull
    color:notnull
}

# -----------------------------------------------------------------------------

page_validation {
    if { ![regexp "#(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])(\[0-9\]|\[a-f\]|\[A-F\])" $color match] } {
	error "Color must be in form #XXXXXX where X is a hexadecimal character.  You entered: $color"
    }
}

set user_id [ad_maybe_redirect_for_registration]

db_dml topic_update "
UPDATE bboard_unified
SET    color    = :color
WHERE  topic_id = :topic_id
AND    user_id  = :user_id
"

db_release_unused_handles

ad_returnredirect personalize?