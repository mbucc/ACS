# /www/bboard/unified/add-icon.tcl
ad_page_contract {
    Form to add an icon

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id add-icon.tcl,v 1.1.4.4 2000/09/22 01:36:58 kevin Exp
} {
    topic
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------

set page_content "[bboard_header "Upload Icon"]

[ad_decorate_top "<h2>Upload Icon</h2>

[ad_context_bar_ws_or_index [list "/bboard/index" [bboard_system_name]] [list "/bboard/unified" "Personal Forum View"] [list "/bboard/unified/personalize" "Forum View Personalization"] "Upload Icon"]

" [ad_parameter IndexPageDecoration bboard]]

<hr>

[ad_decorate_side]

<blockquote>
<form enctype=multipart/form-data method=POST action=\"add-icon-2\">

<table>

<tr>
<td valign=top align=right>Filename: </td>
<td>
<input type=file name=upload_file size=40 [export_form_value upload_file]><br>
<font size=-1>Use the \"Browse...\" button to locate your file, then click \"Open\".</font>
</td>
</tr>

<tr>
<td valign=top align=right>Short name for icon: </td>
<td>
<input type-text size=25 name=img_name [export_form_value img_name]>
</td>
</tr>

<tr>
<td valign=top align=right> Desired image height (in pixels) </td>
<td>
<input type=text name=img_h [export_form_value img_h]>
</td>
</tr>

<tr>
<td valign=top align=right> Desired image width (in pixels) </td>
<td>
<input type=text maxlength=4 name=img_w [export_form_value img_w]>
</td>
</tr>

</table>
[export_form_vars topic_id topic]
<p>
<center>
<input type=submit value=\"Upload\">
</center>
</blockquote>
</form>

[bboard_footer]
"

doc_return  200 text/html $page_content
