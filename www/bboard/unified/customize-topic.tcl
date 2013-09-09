# /www/bboard/unified/customize-topic.tcl
ad_page_contract {
    Page to customize a bboard topic

    @param topic_id the ID of the bboard topic to customize

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id customize-topic.tcl,v 1.2.2.4 2000/09/22 01:36:59 kevin Exp
} {
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

append page_content "
[bboard_header "Forum View Personalization"]

[ad_decorate_top "<h2>Forum View Personalization</h2>

[ad_context_bar_ws_or_index [list "/bboard/index" [bboard_system_name]] [list "/bboard/unified" "Personal Forum View"] "Customize Forum Color"]

" [ad_parameter IndexPageDecoration bboard]]

<hr>

[ad_decorate_side]

"

db_1row topic_info "
SELECT bboard_topics.topic AS topic, bboard_unified.color AS color
FROM bboard_topics, bboard_unified
WHERE bboard_topics.topic_id = :topic_id
  AND bboard_unified.topic_id=bboard_topics.topic_id
"

db_release_unused_handles

if { [empty_string_p $color] } {
    set font_color ""
} else {
    set font_color "color=$color"
}

append page_content "
    <h3> Customize the color for Forum: <a href=\"/bboard/q-and-a?[export_url_vars topic_id]\"><font size='+1' $font_color>$topic</font></a></h3>

<table align=\"center\" width=\"80%\" border=\"0\" cellspacing=\"10\" cellpadding=\"0\">

<tr><td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/black.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#000000"]&[export_url_vars topic_id]\"><font color=#000000>Black</font></a>
    <td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/green.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#008000"]&[export_url_vars topic_id]\"><font color=#008000>Green</font></a>
    <br></tr>

<tr><td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/silver.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#C0C0C0"]&[export_url_vars topic_id]\"><font color=#C0C0C0>Silver</font></a>
    <td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/lime.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#00FF00"]&[export_url_vars topic_id]\"><font color=#00FF00>Lime</font></a>
    <br></tr>

<tr><td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/gray.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#808080"]&[export_url_vars topic_id]\"><font color=#808080>Gray</font></a>
    <td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/olive.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#808000"]&[export_url_vars topic_id]\"><font color=#808000>Olive</font></a>
    <br></tr>

<tr><td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/white.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#FFFFFF"]&[export_url_vars topic_id]\"><font color=#FFFFFF>White</font></a>
    <td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/yellow.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#FFFF00"]&[export_url_vars topic_id]\"><font color=#FFFF00>Yellow</font></a>
    <br></tr>

<tr><td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/maroon.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#800000"]&[export_url_vars topic_id]\"><font color=#800000>Maroon</font></a>
    <td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/navy.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#000080"]&[export_url_vars topic_id]\"><font color=#000080>Navy</font></a>
    <br></tr>

<tr><td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/red.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#FF0000"]&[export_url_vars topic_id]\"><font color=#FF0000>Red</font></a>
    <td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/blue.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#0000FF"]&[export_url_vars topic_id]\"><font color=#0000FF>Blue</font></a>
    <br></tr>

<tr><td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/purple.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#800080"]&[export_url_vars topic_id]\"><font color=#800080>Purple</font></a>
    <td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/teal.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#008080"]&[export_url_vars topic_id]\"><font color=#008080>Teal</font></a>
    <br></tr>

<tr><td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/fuchsia.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#FF00FF"]&[export_url_vars topic_id]\"><font color=#FF00FF>Fuchsia</font></a>
    <td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/aqua.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "#00FFFF"]&[export_url_vars topic_id]\"><font color=#00FFFF>Aqua</font></a>
    <br></tr>

</table>

[bboard_footer]
"

doc_return  200 text/html $page_content
