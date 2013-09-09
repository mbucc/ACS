# /www/bboard/unified/personalize.tcl
ad_page_contract {
    let the user pick which forums he or she wants to see in a 
    unified view

    @author LuisRodriguez@photo.net
    @creation_date May 2000
    @cvs-id personalize.tcl,v 1.2.2.4 2000/09/22 01:36:59 kevin Exp
} {
}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

set page_content "[bboard_header "Forum View Personalization"]

[ad_decorate_top "<h2>Forum View Personalization</h2>

[ad_context_bar_ws_or_index [list "/bboard/index" [bboard_system_name]] [list "/bboard/unified/" "Personalized Forums"] "Edit Personalization"]

" [ad_parameter IndexPageDecoration bboard]]

<hr>

[ad_decorate_side]

\[ <a href=\"reset-personalization\">Reset personalization</a> \]
<br>

"

set topics_in_user_view [db_string num_user_topics "
SELECT count(*)
FROM bboard_unified
WHERE user_id = :user_id"]

set topics_in_bboard_topics [db_string num_topics "
SELECT count(*)
FROM bboard_topics"]

if { $topics_in_user_view != $topics_in_bboard_topics } {
    db_dml topics_insert "
    INSERT INTO bboard_unified
    (user_id, topic_id, default_topic_p, color, icon_id)
    SELECT :user_id, topic_id, default_topic_p, color, icon_id
    FROM bboard_topics
    WHERE topic_id NOT IN (SELECT topic_id
                           FROM bboard_unified
                           WHERE user_id = :user_id)
    "
}

set active_user_topics [db_string num_active_topics "
SELECT count(*)
FROM bboard_unified
WHERE user_id = :user_id
AND default_topic_p = 't'
"]

if { $active_user_topics == 0 } {
    db_dml active_topics_insert "
    UPDATE bboard_unified
    SET default_topic_p= 't'
    WHERE topic_id IN (SELECT topic_id 
                      FROM bboard_topics
                      WHERE default_topic_p = 't')
      AND user_id = :user_id"
}

# This modified bboard_unify to make sure the user has access to 
# all forums with default_topic_p = 't'
scrub_access_to_unified_topics $user_id

set count 0

db_foreach user_unified_topics "
SELECT DISTINCT bboard_unified.topic_id AS topic_id,
                bboard_topics.topic AS topic,
                UPPER(bboard_topics.topic) AS sort_topic,
                bboard_unified.color AS color, 
                NVL(bboard_unified.icon_id, -1) AS icon_id,
                bboard_unified.default_topic_p AS default_topic_p,
                bboard_topics.read_access AS read_access
FROM bboard_unified, bboard_topics
WHERE bboard_unified.topic_id = bboard_topics.topic_id
AND  bboard_unified.user_id = :user_id
ORDER BY sort_topic" {

    if { [empty_string_p $color] } {
	set aref_color ""
	set font_color ""
    } else {
	set aref_color "style=\"color:$color\""
	set font_color "color=$color"
    }

    if {$count == 0} {
	append whole_page "<form enctype=multipart/form-data method=POST action=\"toggle-p\">
<blockquote>
"
    }
    set checked "checked"
    if { [string compare $default_topic_p "t"] } {
	set checked ""
    }

    if { $icon_id > 0 } {
	set icon_img [icon_id_to_img_html $icon_id]
	set icon_img_action "<font size='-2'><a $aref_color href=\"customize-icon?[export_url_vars topic_id topic]\"> (change icon)</a></font> <font size='-2' $font_color> or </font> "
    } else {
	set icon_img ""
	set icon_img_action "<font size='-2'> <a $aref_color href=\"customize-icon?[export_url_vars topic_id topic]\">(add Icon)</a></font> <font $font_color size='-2'> or </font>"
    }

    append page_content " <input type=\"checkbox\" value=\"$topic_id\" $checked name=\"topic_ids\">$icon_img <a $aref_color href=\"/bboard/q-and-a?[export_url_vars topic_id]\">$topic</a> $icon_img_action<a $aref_color href=\"customize-topic?[export_url_vars topic_id]\"><font $font_color> <font size='-2'>(change color)</a></font></font> <br>\n"
    incr count
}

db_release_unused_handles

if {$count != 0} {
    append page_content "  <p> <input type=\"submit\" name=\"Update\" value=\"Update Forum Selection\"> \n</blockquote></form>"
}
append page_content "

[ad_style_bodynote "If don't select any forums, your unified view will show the publisher's selections."]

[bboard_footer]
"

doc_return  200 text/html $page_content
