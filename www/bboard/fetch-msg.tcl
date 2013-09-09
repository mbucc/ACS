
ad_page_contract {
    displays one message
    @param msg_id - the message id

    @cvs-id fetch-msg.tcl,v 3.3.2.6 2000/09/22 01:36:50 kevin Exp
} {
    msg_id
}


if [bboard_file_uploading_enabled_p] {
    db_1row bb_fmsg_msg "
    select round(sysdate - posting_time) as days_since_posted
    , email
    , bboard.topic_id
    , bboard.one_line
    , bboard.message
    , bboard.html_p
    , first_names || ' ' || last_name as name
    , bboard_topics.topic
    , users.user_id as poster_user_id 
    , buf.bboard_upload_id
    , buf.file_type
    , buf.n_bytes 
    , buf.client_filename
    , buf.caption
    , buf.original_width
    , buf.original_height
    from bboard, bboard_topics, users, bboard_uploaded_files buf
    where bboard.user_id = users.user_id 
    and bboard_topics.topic_id = bboard.topic_id
    and bboard.msg_id = buf.msg_id(+)
    and bboard.msg_id = :msg_id"
} else {
    db_1row bb_fmsg_msg "
    select round(sysdate - posting_time) as days_since_posted
    , bboard.topic_id
    , bboard.one_line
    , bboard.message
    , bboard.html_p
    , email
    , first_names || ' ' || last_name as name
    , bboard_topics.topic 
    , users.user_id as poster_user_id 
    from bboard, bboard_topics, users
    where bboard.user_id = users.user_id 
    and bboard_topics.topic_id = bboard.topic_id
    and msg_id = :msg_id"
}

# now variables like $message and topic are defined
if {[bboard_get_topic_info] == -1} {
    return
}

# deal with upload
if { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type == "photo" && $n_bytes > 0 } {
    # ok, we have a photo; the question is how big is it 
    if [empty_string_p $original_width] {
	# we don't know how big it is so it probably wasn't a JPEG or GIF
	
	regsub -all {[^-_.0-9a-zA-Z]+} $client_filename "_" pretty_filename
	
	set upload "<center>(undisplayable image: <i>$caption</i> -- <a href=\"download-file/$bboard_upload_id/$pretty_filename\">$client_filename</a>)</center>"
    } elseif { $original_width < 512 } {
	set upload "<center>\n<img height=$original_height width=$original_width hspace=5 vspace=10 src=\"image.tcl?[export_url_vars bboard_upload_id]\">\n<br><i>$caption</i>\n</center>\n<br>"
    } else {
	set upload "<center><a href=\"big-image?[export_url_vars bboard_upload_id]\">($caption -- $original_height x $original_width $file_type)</a></center>"
    }
} elseif { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type != "photo" } {
    regsub -all {[^-_.0-9a-zA-Z]+} $client_filename "_" pretty_filename
    set upload "<br>Attachment:  <a href=\"download-file/$bboard_upload_id/$pretty_filename\">$client_filename</a>\n"
} else {
    set upload ""
}

switch $days_since_posted { 

	0 { set age_string "today" }

	1 { set age_string "yesterday" }

	default { set age_string "$days_since_posted days ago" }

} 


doc_return  200 text/html "<html>
<head>
<title>$one_line</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<base target=\"link_from_a_message\">

\[
<a target=\"_self\" href=\"post-new?[export_url_vars topic topic_id]\">Post New Message</a> |
<a target=\"_top\" href=\"post-reply-frame?refers_to=$msg_id\">Post Reply to this One</a> | 
<a href=\"mailto:$email\">Send Private Email to $name</a> |
<a target=\"_self\" href=\"default-main?[export_url_vars topic topic_id]\">Help</a>
\]

<p>
<h3>$one_line</h3>
from <a href=\"contributions?user_id=$poster_user_id\">$name</a>
<blockquote>
[ad_convert_to_html -html_p $html_p -- $message]
<p>
$upload
</blockquote>
(posted $age_string)
<p>
\[
<a target=\"_self\" href=\"prev?msg_id=$msg_id&[export_url_vars topic topic_id]\">Previous</a> |
<a target=\"_self\" href=\"next?msg_id=$msg_id&[export_url_vars topic topic_id]\">Next</a>

\]

[bboard_footer]
"
