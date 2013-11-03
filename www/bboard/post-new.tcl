# /www/bboard/post-new.tcl

ad_page_contract {
    Page to post new message
    @author unknown
    @creation-date unknown
    @cvs-id post-new.tcl,v 3.4.2.3 2000/09/22 01:36:51 kevin Exp
} {
    topic:trim
    topic_id:integer
} 

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

if {[bboard_get_topic_info] == -1} {
    return
}

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {

   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_partial_url_stub]post-new.tcl?[export_url_vars topic topic_id]"]
    return
}

if { [bboard_pls_blade_installed_p] } {
    set search_option "Note:  before you post a new question, you might want to make sure that it hasn't already been asked and answered... 
<form method=GET action=search target=\"_top\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
Full Text Search:  <input type=text name=query_string size=40>
</form>

$pre_post_caveat

<hr>
"
} else {
    set search_option "$pre_post_caveat"
}

set page_content "[ad_header "" "Post a New Message"]

<h3>Post a New Message</h3>

into the <a href=\"main-frame?[export_url_vars topic topic_id]\" target=\"_top\">$topic</a> bboard

<hr>

$search_option

<form method=post action=\"confirm\" target=\"_top\">

<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
<input type=hidden name=refers_to value=NEW>

<table>

<tr><th align=left>Subject Line<td><input type=text name=one_line size=50></tr>

<tr><th align=left>Notify Me of Responses<br>(via email)
<td><input type=radio name=notify value=t CHECKED> Yes
<input type=radio name=notify value=f> No
</tr>

<tr><th>Message<br><td>enter in textarea below, then press submit
</tr>

<tr><td colspan=2>
<textarea name=message rows=10 cols=70 wrap=physical></textarea>
</td></tr>
<tr><th align=left>Text above is:
<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
</table>
<P>

<center>

<input type=submit value=Submit>

</center>

</form>

[bboard_footer]
"

doc_return  200 text/html $page_content









