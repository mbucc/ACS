# $Id: usgeospatial-post-reply-form.tcl,v 3.0.4.1 2000/04/28 15:09:45 carsten Exp $
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

   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_partial_url_stub]usgeospatial-post-reply-form.tcl?refers_to=$form_refers_to"]
    return
}


set selection [ns_db 0or1row $db "select users.first_names || ' ' || users.last_name as name, bboard.*, users.*  from bboard, users 
where users.user_id = bboard.user_id
and msg_id = '$form_refers_to'"]

if { $selection == "" } {
    # message was probably deleted
    ns_return 200 text/html "Couldn't find message $msg_id.  Probably the message to which you are currently trying to reply has deleted by the forum maintainer."
    return
}


set_variables_after_query

if [catch {set selection [ns_db 1row $db "select unique * from bboard_topics where topic='[DoubleApos $topic]'"]} errmsg] {
    bboard_return_cannot_find_topic_page
    return
}
set_variables_after_query



ReturnHeaders 

ns_write "[bboard_header "Respond"]

<h2>Respond</h2>

to \"$one_line\"

<p>

in <a href=\"usgeospatial-2.tcl?[export_url_vars topic epa_region]\">the $topic (region $epa_region) forum</a>

<hr>

<h3>Original Posting</h3>

$message

<p>

from $name (<a href=\"mailto:$email\">$email</a>)

<hr>

<form method=post action=\"insert-msg.tcl\">

<input type=hidden name=usgeospatial_p value=t>
<input type=hidden name=refers_to value=$form_refers_to>
<b>One-line</b> summary of response<p>
<blockquote>
<input type=text name=one_line size=65 value=\"Response to [philg_quote_double_quotes $one_line]\">
</blockquote>
<p>
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
<input type=hidden name=notify value=f>

<table>

<tr><th>Response<td> &nbsp;</tr>

</table>

<p>

<blockquote>

<textarea name=message rows=8 cols=70 wrap=hard></textarea>

</blockquote>

<p>

<center>
<input type=submit value=Respond>
</center>
</form>
"

set QQtopic [DoubleApos $topic]
bboard_get_topic_info

ns_write "

[bboard_footer]
"
