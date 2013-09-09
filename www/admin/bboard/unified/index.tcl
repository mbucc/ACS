# /www/admin/bboard/unified/index.tcl
ad_page_contract {
    Hyper-admin for unified stuff

    @author raj@alum.mit.edu
    @creation-date 19 May 2000
    @cvs-id index.tcl,v 1.2.2.4 2000/09/22 01:34:23 kevin Exp
} {
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

set page_content "
[ad_admin_header "[bboard_system_name]  Default Forums Admin"]
<h2> Default Topic Administration </h2>
[ad_admin_context_bar {"/admin/bboard" "BBoard Hyper-Administration" } "Default Forums Administration"]
<hr>

<h2> Select default forums and settings for new users</h2>"

set count 0

db_foreach bboard_topics "
SELECT topic_id,
       topic,
       default_topic_p,
       color,
       NVL(icon_id,-1) AS icon_id,
       UPPER(topic) AS sort_topic
       FROM bboard_topics 
ORDER BY sort_topic ASC
" {

    if { [empty_string_p $color] } {
	set style_color ""
	set font_color ""
    } else {
	set style_color "style=color:$color"
	set font_color "color=$color"
    }
    
    if {$count == 0} {
	append page_content "<form enctype=multipart/form-data method=POST action=\"toggle-p\">"
    }

    set checked "checked"
    if { [string compare $default_topic_p "t"] } {
	set checked ""
    }

    if { $icon_id > 0 } {
	set icon_img [icon_id_to_img_html $icon_id]
	set icon_img_action "<font size='-2'><a $style_color href=\"customize-icon?[export_url_vars topic_id topic]\"> (change icon)</a></font> <font size='-2' $font_color> or </font> "
    } else {
	set icon_img ""
	set icon_img_action "<font size='-2'> <a $style_color href=\"customize-icon?[export_url_vars topic_id topic]\">(add Icon)</a> </font> <font size='-2' $font_color> or </font>"
    }

    append page_content " <input type=\"checkbox\" value=\"$topic_id\" $checked name=\"topic_ids\"> $icon_img <a $style_color href=\"/bboard/q-and-a.tcl?[export_url_vars topic_id]\">$topic</a> $icon_img_action <a $style_color href=\"customize-topic?[export_url_vars topic_id]\"><font size='-2'>(Change default color)</a></font> <br>\n"
    incr count
}

db_release_unused_handles

if { $count != 0 } {
    append page_content "  <p> <input type=\"submit\" name=\"Update\" value=\"Update\"> \n</form>"
}

append page_content [ad_admin_footer]

doc_return  200 text/html $page_content
