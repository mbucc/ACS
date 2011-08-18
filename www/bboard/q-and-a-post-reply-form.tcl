# $Id: q-and-a-post-reply-form.tcl,v 3.0.4.1 2000/04/28 15:09:43 carsten Exp $
# q-and-a-post-reply-form.tcl
#
# philg@arsdigita.com, hqm@arsdigita.com
#


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set form_refers_to [ns_queryget refers_to]

# we can't just use set_form_variables because that would set
# "refers_to" which is about to be overwritten by the db query

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_partial_url_stub]q-and-a-post-reply-form.tcl?refers_to=$form_refers_to"]
    return
}

set selection [ns_db 0or1row $db "select users.user_id, users.first_names || ' ' || users.last_name as name, 
bboard.topic_id, bboard_topics.topic, bboard.category, bboard.one_line, bboard.message, bboard.html_p
from bboard, users, bboard_topics
where bboard_topics.topic_id = bboard.topic_id 
and users.user_id = bboard.user_id
and msg_id = '$form_refers_to'"]

if { $selection == "" } {
    # message was probably deleted
    ns_return 200 text/html "Couldn't find message $form_refers_to.  Probably the message to which you are currently trying to reply has deleted by the forum maintainer."
    return
}


set_variables_after_query

if [catch {set selection [ns_db 1row $db "select unique * from bboard_topics where topic_id=$topic_id"]} errmsg] {
    bboard_return_cannot_find_topic_page
    return
}
set_variables_after_query



ReturnHeaders 

ns_write "[bboard_header "Post Answer"]


<h3>Post an Answer</h3>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Post Answer"]

<hr>

<h3>Original question</h3>

<blockquote>
Subject: $one_line
<br>
<br>
[util_maybe_convert_to_html $message $html_p]
<br>
<br>
-- [ad_present_user $user_id $name]
</blockquote>

<h3>Your Response</h3>

<blockquote>
<form method=post action=\"confirm.tcl\">
[export_form_vars topic topic_id category]
<input type=hidden name=q_and_a_p value=t>
<input type=hidden name=refers_to value=$form_refers_to>
<input type=hidden name=notify value=f>


<b>Subject:</b>
<br>
<input type=text name=one_line size=70 value=\"Response to [philg_quote_double_quotes $one_line]\">

<p>


<b>Answer:</b>

<br>

<textarea name=message rows=8 cols=70 wrap=physical></textarea>

<p>
The above text is:
<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>

<br><br>
<center>
<input type=submit value=Submit>
</center>
</form>
</blockquote>
</body>
</html>
"
