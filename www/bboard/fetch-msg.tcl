# $Id: fetch-msg.tcl,v 3.0 2000/02/06 03:33:52 ron Exp $
set_form_variables

# msg_id is the key

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


set selection [ns_db 1row $db "select round(sysdate - posting_time) as days_since_posted,bboard.*, email, first_names || ' ' || last_name as name, bboard_topics.topic,
users.user_id as poster_user_id 
from bboard, bboard_topics, users
where bboard.user_id = users.user_id 
and bboard_topics.topic_id = bboard.topic_id
and msg_id = '$msg_id'"]

set_variables_after_query

# now variables like $message and topic are defined

set QQtopic [DoubleApos $topic]
if {[bboard_get_topic_info] == -1} {
    return
}



switch $days_since_posted { 

	0 { set age_string "today" }

	1 { set age_string "yesterday" }

	default { set age_string "$days_since_posted days ago" }

} 


ns_return 200 text/html "<html>
<head>
<title>$one_line</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<base target=\"link_from_a_message\">

\[
<a target=\"_self\" href=\"post-new.tcl?[export_url_vars topic topic_id]\">Post New Message</a> |
<a target=\"_top\" href=\"post-reply-frame.tcl?refers_to=$msg_id\">Post Reply to this One</a> | 
<a href=\"mailto:$email\">Send Private Email to $name</a> |
<a target=\"_self\" href=\"default-main.tcl?[export_url_vars topic topic_id]\">Help</a>
\]

<p>

<h3>$one_line</h3>

from <a href=\"contributions.tcl?user_id=$poster_user_id\">$name</a>

<blockquote>

[util_maybe_convert_to_html $message $html_p]

</blockquote>

(posted $age_string)

<p>

\[
<a target=\"_self\" href=\"prev.tcl?msg_id=$msg_id&[export_url_vars topic topic_id]\">Previous</a> |
<a target=\"_self\" href=\"next.tcl?msg_id=$msg_id&[export_url_vars topic topic_id]\">Next</a>

\]

[bboard_footer]
"
