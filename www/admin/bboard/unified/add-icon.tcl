# /www/admin/bboard/unified/add-icon.tcl
ad_page_contract {
    Add an icon to be displayed with postings

    @param topic_id the ID of the topic to associate the icon with
    @param topic the name of the topic
    
    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id
} {
    topic_id:integer,notnull
    topic:notnull
}

# -----------------------------------------------------------------------------

set page_content "
[ad_admin_header "[bboard_system_name]  Default Forums Admin"]

<h2> Upload Icon </h2>

[ad_admin_context_bar {"/admin/bboard" "BBoard Hyper-Administration" } {"/admin/bboard/unified" "Default Forums Administration"} "Upload Icon"]

<hr>

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

[ad_admin_footer]
"

doc_return  200 text/html $page_content
