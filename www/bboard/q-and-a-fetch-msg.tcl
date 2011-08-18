# /www/bboard/q-and-a-fetch-msg.tcl
#
# displays one thread (question and answer)
#
# by philg@mit.edu back in 1995
#
# $Id: q-and-a-fetch-msg.tcl,v 3.0.4.2 2000/03/18 02:06:43 ron Exp $

set_form_variables 0

# msg_id 

if { ![info exists msg_id] || [empty_string_p $msg_id] } {
    ad_return_complaint 1 "<li>You've asked for a bboard posting but didn't specify a message ID.  We think that you're probably a search engine robot.  Holler if you aren't."
    return
}

# msg_id is the key
# make a copy because it is going to get overwritten by 
# some subsequent queries

set this_msg_id $msg_id

set db [bboard_db_gethandle]

if [bboard_file_uploading_enabled_p] {
    set query "select 
 posting_time as posting_date,
 bboard.msg_id,
 bboard.topic_id,
 bboard_topics.topic,
 bboard.one_line,
 bboard.message,
 bboard.html_p,
 users.user_id as poster_id,  
 users.first_names || ' ' || users.last_name as name, 
 buf.bboard_upload_id,
 buf.file_type,
 buf.n_bytes,
 buf.client_filename,
 buf.caption,
 buf.original_width,
 buf.original_height
from bboard, bboard_topics, users, bboard_uploaded_files buf
where bboard_topics.topic_id = bboard.topic_id
and bboard.user_id = users.user_id
and bboard.msg_id = buf.msg_id(+)
and bboard.msg_id = '$msg_id'"
} else {
    set query "select posting_time as posting_date,bboard.*, users.user_id as poster_id,  users.first_names || ' ' || users.last_name as name, html_p
from bboard, users
where bboard.user_id = users.user_id
and msg_id = '$msg_id'"
}

set selection [ns_db 0or1row $db $query]

if { $selection == "" } {
    # message was probably deleted
    ns_return 200 text/html "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    return
}

set_variables_after_query
set this_one_line $one_line

# now variables like $message and $topic are defined

set QQtopic [DoubleApos $topic]
if {[bboard_get_topic_info] == -1} {
    return
}


if [catch {set selection [ns_db 1row $db "select bt.*, u.email as maintainer_email 
from bboard_topics bt, users u 
where bt.topic_id=$topic_id
and bt.primary_maintainer_id = u.user_id"]} errmsg] {
    bboard_return_cannot_find_topic_page
    return
}
set_variables_after_query


# Present thread alert link in upper right if they are logged in and have not
# already asked for an alert, or are not logged in.  Otherwise give stop notification link.
set user_id [ad_get_user_id]
if { [ad_parameter EnableThreadEmailAlerts bboard 1] && !$user_id || ![database_to_tcl_string $db "select count(*)
from bboard_thread_email_alerts where user_id = $user_id
 and thread_id = '$this_msg_id'"] } {
    set thread_alert_link [help_upper_right_menu [list "q-and-a-thread-alert.tcl?thread_id=$this_msg_id" "Notify me of new responses"]]
 } else {
    set thread_alert_link [help_upper_right_menu [list "q-and-a-thread-unalert.tcl?thread_id=$this_msg_id" "Stop notifying me of new responses"]]
}

append whole_page "[bboard_header $one_line]

<h3>$one_line</h3>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "One Thread"]


<hr>
$thread_alert_link

<blockquote>
"

if { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type == "photo" && $n_bytes > 0 } {
    # ok, we have a photo; the question is how big is it 
    if [empty_string_p $original_width] {
	# we don't know how big it is so it probably wasn't a JPEG or GIF
	append whole_page "<center>(undisplayable image: <i>$caption</i> -- <a href=\"uploaded-file.tcl?[export_url_vars bboard_upload_id]\">$client_filename</a>)</center>"
    } elseif { $original_width < 512 } {
	append whole_page "<center>\n<img height=$original_height width=$original_width hspace=5 vspace=10 src=\"image.tcl?[export_url_vars bboard_upload_id]\">\n<br><i>$caption</i>\n</center>\n<br>"
    } else {
	append whole_page "<center><a href=\"big-image.tcl?[export_url_vars bboard_upload_id]\">($caption -- $original_height x $original_width $file_type)</a></center>"
    }
}

append whole_page "[util_maybe_convert_to_html $message $html_p]
<br>
<br>
-- [ad_present_user $poster_id $name], [util_AnsiDatetoPrettyDate $posting_date]
"

if { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type != "photo" } {
    append whole_page "<br>Attachment:  <a href=\"uploaded-file.tcl?[export_url_vars bboard_upload_id]\">$client_filename</a>\n"
}

append whole_page "


</blockquote>

"

if [bboard_file_uploading_enabled_p] {
    set extra_select ", buf.bboard_upload_id, client_filename, file_type, buf.n_bytes,  buf.caption, buf.original_width, buf.original_height"
    set extra_table ", bboard_uploaded_files buf"
    set extra_and_clause "\nand bboard.msg_id = buf.msg_id(+)"
} else {
    set extra_select ""
    set extra_table ""
    set extra_and_clause ""
}

set selection [ns_db select $db "select decode(email,'$maintainer_email','f','t') as not_maintainer_p, posting_time as posting_date, bboard.*, 
users.user_id as replyer_user_id,
users.first_names || ' ' || users.last_name as name, users.email $extra_select
from bboard, users $extra_table
where users.user_id = bboard.user_id $extra_and_clause
and sort_key like '$msg_id%'
and bboard.msg_id <> '$msg_id'
order by not_maintainer_p, sort_key"]


while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set this_response ""
    if { $one_line != $this_one_line && $one_line != "Response to $this_one_line" } {
	# new subject
	append this_response "<h4>$one_line</h4>\n"
    }
    append this_response "<blockquote>"

    if { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type == "photo" && $n_bytes > 0 } {
	# ok, we have a photo; the question is how big is it 
	if [empty_string_p $original_width] {
	    # we don't know how big it is, so it probably wasn't a JPEG or GIF
	    append this_response  "<center>(undisplayable image: <i>$caption</i> -- <a href=\"uploaded-file.tcl?[export_url_vars bboard_upload_id]\">$client_filename</a>)</center>"
	} elseif { $original_width < 512 } {
	    append this_response "<center>\n<img height=$original_height width=$original_width hspace=5 vspace=10 src=\"image.tcl?[export_url_vars bboard_upload_id]\">\n<br><i>$caption</i>\n</center>\n<br>"
	} else {
	    append this_response "<center><a href=\"big-image.tcl?[export_url_vars bboard_upload_id]\">($caption -- $original_height x $original_width $file_type)</a></center>"
	}
    }

    append this_response "[util_maybe_convert_to_html $message $html_p]
<br>
<br>
-- [ad_present_user $replyer_user_id $name], [util_AnsiDatetoPrettyDate $posting_date]
"
    if { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type != "photo" } {
	append this_response "<br>Attachment:  <a href=\"uploaded-file.tcl?[export_url_vars bboard_upload_id]\">$client_filename</a>\n"
    }
    append this_response "\n\n</blockquote>\n\n"
    lappend responses $this_response
}

if { [info exists responses] } {
    # there were some
    append whole_page "<h3>Answers</h3>
[join $responses "<hr width=300>"]
"
}
    

append whole_page "
<center>

<form method=POST action=\"q-and-a-post-reply-form.tcl\">
<input type=hidden name=refers_to value=\"$this_msg_id\">
<input type=submit value=\"Contribute an answer\">
</form>

</center>
</body>
</html>

"

ns_db releasehandle $db

ns_return 200 text/html $whole_page
