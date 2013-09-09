# /www/admin/bboard/unified/customize-icon.tcl
ad_page_contract {
    Form to customize the icon for a topic

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard_topic
    
    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id customize-icon.tcl,v 1.1.4.4 2000/09/22 01:34:23 kevin Exp
} {
    topic_id:integer,notnull
    topic:notnull
}

# -----------------------------------------------------------------------------

ad_maybe_redirect_for_registration

set page_content "
[ad_admin_header "[bboard_system_name]  Default Forums Admin"]
<h2> Default Forum Icon Administration </h2>
[ad_admin_context_bar {"/admin/bboard" "BBoard Hyper-Administration" } {"/admin/bboard/unified" "Default Forums Administration"} "Default Forum Icon Customization"]
<hr>

"

set table_state 0
set icon_selection ""
set icon_dir [ad_parameter IconSrc bboard/unified "/bboard/unified/icons"]

db_foreach bboard_icons "
SELECT icon_id, icon_file, icon_name, icon_height, icon_width
FROM bboard_icons
ORDER BY icon_name ASC
" {

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
    set icon_selection_html "<ul> <li> No icons available... would you like to <a href=\"add-icon?[export_url_vars topic_id topic]\">upload an icon? </a> </ul>"
} elseif { $table_state == 2 } {
    set icon_selection_html "
    \[ <a href=\"add-icon?[export_url_vars topic_id topic]\">Upload New Icon</a> \]
    <br>    <br>
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
    \[ <a href=\"add-icon?[export_url_vars topic_id topic]\">Add New Icon</a> \]
    <br>    <br>
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
[ad_admin_footer]
"

doc_return  200 text/html $page_content
