# /www/bboard/unified/customize-topic.tcl
ad_page_contract {
    Page to customize a bboard topic

    @param topic_id the ID for the bboard topic

    @author LuisRodriguez@photo.net
    @cvs-id customize-topic.tcl,v 1.2.2.4 2000/09/22 01:34:23 kevin Exp
} {
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------


ad_maybe_redirect_for_registration

set page_content 
"[ad_admin_header "[bboard_system_name]  Default Forums Admin"]

<h2> Default Topic Administration </h2>

[ad_admin_context_bar {"/admin/bboard" "BBoard Hyper-Administration" } {"/admin/bboard/unified" "Default Forums Administration"} "Default Forum Customization"]
<hr>"

db_1row topic_color "
SELECT topic, color
FROM bboard_topics
WHERE bboard_topics.topic_id = :topic_id"

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
    <td><a href=\"customize-color?color=[ns_urlencode "\#000000"]&[export_url_vars topic_id]\"><font color=#000000>Black</font></a>
    <td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/green.gif\"> 
    <td><a href=\"customize-color?color=[ns_urlencode "\#008000"]&[export_url_vars topic_id]\"><font color=\#008000>Green</font></a>
    <br></tr>

<tr><td width=\"16\"> <img alt=\"\" src=\"/bboard/unified/colors/silver.gif\">
    <td><a href=\"customize-color?color=[ns_urlencode "\#C0C0C0"]&[export_url_vars topic_id]\"><font color=#C0C0C0>Silver</font></a>
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

[ad_admin_footer]
"

doc_return  200 text/html $page_content