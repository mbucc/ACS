# $Id: confirm.tcl,v 3.0.4.1 2000/04/28 15:09:41 carsten Exp $
# confirm.tcl
#
# display a confirmation page for new news postings
# philg@arsdigita.com

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl"
    return
}

set_the_usual_form_variables

set db [ns_db gethandle]
if {[bboard_get_topic_info] == -1} {
    return
}

# message, one_line, notify, html_p
# topic, topic_id are hidden vars
# q_and_a_p is an optional variable, if set to "t" then this is from 
# the Q&A forum version
# refers_to is "NEW" or a msg_id (six characters)

set exception_text ""
set exception_count 0

if { ![info exists one_line] || [empty_string_p $one_line] } {
    append exception_text "<li>You need to type a subject line\n"
    incr exception_count
}

if { ![info exists message] || [empty_string_p $message] } {
    append exception_text "<li>You need to type a message; there is no \"Man/woman of Few Words Award\" here. \n"
    incr exception_count
}


if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}

set presentation_type [database_to_tcl_string $db "select presentation_type from bboard_topics where topic_id = $topic_id"]

ReturnHeaders

ns_write "[bboard_header "Confirm"]

<h2>Confirm</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Confirm Posting"]

<hr>

<blockquote>
Subject: $one_line
<br>
<br>

"

if { [info exists html_p] && $html_p == "t" } {
    ns_write "$message
</blockquote>

Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"

} else {
    ns_write "[util_convert_plaintext_to_html $message]
</blockquote>

Note: if the story has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}


if {![bboard_file_uploading_enabled_p] || [empty_string_p $uploads_anticipated]} {
    set extra_form_tag ""
    set extra_form_contents ""
} elseif { [bboard_file_uploading_enabled_p] && $uploads_anticipated == "images" } {
    set extra_form_tag "enctype=multipart/form-data"
    set extra_form_contents "
<center>
<table bgcolor=#EEEEEE cellpadding=5 width=80%>
<tr><td colspan=2 align=center>You may upload an image with this posting.</td></tr>
<tr>
<th>
Filename 
<td>
<INPUT TYPE=file name=upload_file>
<br>
(<font size=-1>on your local hard drive</font>)
</tr>
<tr>
<th>
Caption
<td><INPUT TYPE=text name=caption size=50>
</tr>
<tr><td>&nbsp;
<td>
<blockquote>
<i>Note:  GIF and JPEG images are the only ones that can be displayed by most browsers.  So if the file you're uploading doesn't end in .jpg, .jpeg, or .gif it probably won't be viewable by most users.
</i>
</blockquote>
</td>
</tr>
</table>
</center>
<p>"
} elseif { [bboard_file_uploading_enabled_p] && $uploads_anticipated == "files" } {
    set extra_form_tag "enctype=multipart/form-data"
    set extra_form_contents "

<p>

You may upload a file with this posting: 
<INPUT TYPE=file name=upload_file>


<p>" 
} elseif { [bboard_file_uploading_enabled_p] && $uploads_anticipated == "images_or_files" } {
    set extra_form_tag "enctype=multipart/form-data"
    set extra_form_contents "
<center>
<table bgcolor=#EEEEEE width=80% cellspacing=5 cellpadding=5>
<tr>
<td>
You may upload a file or image with this posting: 
<INPUT TYPE=file name=upload_file><br>
if this is an image, you can indicate
that by typing in a caption: <INPUT TYPE=text name=caption size=50 maxlength=50>
<p>
<i>Note:  GIF and JPEG images are the only ones that can be displayed by most browsers.  So if the file you're uploading doesn't end in .jpg, .jpeg, or .gif it probably won't be viewable by most users.
</i>
</td>
</tr>
</table>
</center>
<p>" 
} else {
    ns_write "Oops!  We're confronted with uploads_anticipated of \"$uploads_anticipated\".

<p>

We don't know what to do with this.
[bboard_footer]
"
    return
}

# we will pass the entire form forward to the next
# page.  THerefore, we must delete urgent_p from ns_conn form
# so it doesn't get sent twice

ns_set delkey [ns_conn form] urgent_p
if ![info exists urgent_p] {
    set urgent_p "f"
}

ns_write "

<form $extra_form_tag method=post action=\"insert-msg.tcl\">
[export_entire_form]
$extra_form_contents
"

if { $refers_to == "NEW" && [ad_parameter UrgentMessageEnabledP "bboard" 0] } {
    ns_write "
<p>
You can elect to mark this message urgent.  For 
 [ad_parameter DaysConsideredUrgent bboard]
days after posting, your question will be put in front of other users.

<p>

Is this really urgent?
<select name=\"urgent_p\">
 [html_select_value_options [list {"f" "no"} {"t" "yes"}] $urgent_p]</select>
"

} else {
    ns_write "[export_form_vars urgent_p]\n"
}

ns_write "<center>
<input type=submit value=\"Confirm\">
</center>
</form>

</body>
</html>
"
