# /www/bboard/unified/customize-icon.tcl
ad_page_contract {
    Form to customize the icon for one topic

    @param topic_id the ID for the bboard topic
    @param topic the name of the bboard topic

    @author LuisRodriguez@photo.net
    @creation_date May 2000
    @cvs-id customize-icon.tcl,v 1.2.2.6 2000/09/22 01:36:59 kevin Exp
} {
    topic_id:integer,notnull
    topic
}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

append page_content "
[bboard_header "Forum Icon Personalization"]

[ad_decorate_top "<h2>Forum Icon Personalization</h2>

[ad_context_bar_ws_or_index [list "/bboard/index" [bboard_system_name]] \
	[list "/bboard/unified" "Personal Forum View"] \
	"Personalize Forum Icon"]

" [ad_parameter IndexPageDecoration bboard]]

<hr>

[ad_decorate_side]

"

set table_state 0
set icon_selection ""
set icon_dir [ad_parameter IconSrc bboard/unified "/bboard/unified/icons"]

db_foreach icon_info "
SELECT icon_id, icon_file, icon_name, icon_height, icon_width
FROM bboard_icons
ORDER BY icon_name ASC" {

    if { [empty_string_p $icon_name] } {
	set icon_name "Icon $icon_id"
    }

    incr table_state
    if { $table_state == 1} {
	append icon_selection "
	<td width=\"16\"> <img alt=\"$icon_name\" width=$icon_width height=$icon_height src=\"$icon_dir/$icon_file\">
	<td><a href=\"customize-icon-2?[export_url_vars topic_id topic icon_id]\">$icon_name</font></a>
	<br></tr>"
	
    } else {
	append icon_selection "
	<tr><td width=\"16\"> <img alt=\"$icon_name\" width=$icon_width height=$icon_height src=\"$icon_dir/$icon_file\">
	<td><a href=\"customize-icon-2?[export_url_vars topic_id topic icon_id]\">$icon_name</font></a>"
	incr table_state -2
    }
}

db_release_unused_handles

if { [empty_string_p $icon_selection] } {
    set icon_selection_html "<ul> <li> Sorry, there are no icons available at the moment."

    if {![empty_string_p [ad_parameter IconDir bboard/unified ""]]} {
	append icon_selection_html "Would you like to <a href=\"add-icon?[export_url_vars topic_id topic]\">upload an icon? </a>"
    }

    append icon_selection_html "</ul>"
} elseif { $table_state == 2 } {

    if {![empty_string_p [ad_parameter IconDir bboard/unified ""]]} {
	set icon_selection_html "    \[ <a href=\"add-icon?[export_url_vars topic_id topic]\">Upload New Icon</a> \]
    <br>    <br>"
    }

    append icon_selection_html "

    <table align=\"center\" width=\"80%\" cellspacing=\"10\" cellpadding=\"0\">

    <tr>
    <td width=\"16\"> 
    <td><a href=\"no-icon?[export_url_vars topic_id icon_id]\">No Icon</font></a>
    <br></tr>

    $icon_selection
    <td width=\"16\"> 
    <td>
    <br></tr></table>"
} else {
    set icon_selection_html "
    \[ <a href=\"add-icon?[export_url_vars topic_id topic]\">Upload New Icon</a> \]
    <br> <br>

    <table align=\"center\" width=\"80%\" cellspacing=\"10\" cellpadding=\"0\">
    <td width=\"16\"> 
    <td><a href=\"no-icon?[export_url_vars topic_id icon_id]\">No Icon</font></a>
    <br></tr>
    $icon_selection
    </table>"
}

append page_content "
<h3> Choose an icon for Forum: <a href=\"/bboard/q-and-a?[export_url_vars topic_id]\">$topic</a></h3>

$icon_selection_html
[bboard_footer]
"

doc_return  200 text/html $page_content