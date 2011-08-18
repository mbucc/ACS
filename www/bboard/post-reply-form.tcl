# $Id: post-reply-form.tcl,v 3.1.4.1 2000/04/28 15:09:42 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set form_refers_to [ns_set get [ns_conn form] refers_to]

# we can't just use set_form_variables because that would set
# "refers_to" which is about to be overwritten by the db query

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}



set selection [ns_db 1row $db "select  first_names || ' ' || last_name as name, bboard.*, bboard_topics.topic
from bboard, users, bboard_topics
where users.user_id = bboard.user_id
and bboard_topics.topic_id = bboard.topic_id
and msg_id = '$form_refers_to'"]

set_variables_after_query


set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {

   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_partial_url_stub]post-reply-frame.tcl?refers_to=[ns_urlencode $form_refers_to]"]
    return
}


ns_return 200 text/html "<html>
<head>
<title>Post Reply</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h3>Post a Reply</h3>

to \"$one_line\" from $name

<p>

in the <a href=\"main-frame.tcl?[export_url_vars topic topic_id]\" target=\"_top\">$topic</a> bboard

<hr>

<form method=post action=\"confirm.tcl\" target=\"_top\">

[export_form_vars topic topic_id]
<input type=\"hidden\" name=\"refers_to\" [export_form_value form_refers_to]>

<table>


<tr><th>Subject Line<td><input type=text name=one_line size=50></tr>

<tr><th>Message<td><textarea name=message rows=6 cols=70 wrap=physical></textarea></tr>

<tr><th>Notify Me of Responses<br>(via email)
<td><input type=radio name=notify value=t CHECKED> Yes
<input type=radio name=notify value=f> No
</tr>
<tr><th align=left>Text above is:<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
</table>

<input type=submit value=Submit>

</form>

[bboard_footer]
"
