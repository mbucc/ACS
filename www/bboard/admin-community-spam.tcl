# $Id: admin-community-spam.tcl,v 3.0 2000/02/06 03:32:41 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, n_postings, start_date, end_date, from_address, subject, message 

# we substituted wrap=hard instead
# set message [wrap_string $message]



set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}



ReturnHeaders

ns_write "<html>
<head>
<title>Spamming participants in $topic forum</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Spamming participants in $topic forum</h2>

(<a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">main admin page</a>)

<hr>

Proceeding to spam the participants who've made at least $n_postings
postings between $start_date and $end_date...

<pre>
From: $from_address
Subject: $subject
---- body ---
$message
</pre>

<ul>

"

if { $n_postings < 2 } {
    set sql "select distinct bboard.user_id,  count(bboard.user_id) as how_many_posts, upper(email) as upper_email,email
from bboard, users
where bboard.user_id = users.user_id 
and topic_id = $topic_id
and posting_time >= to_date('$start_date','YYYY-MM-DD')
and posting_time <= to_date('$end_date','YYYY-MM-DD')
group by bboard.user_id, email
order by upper_email"
} else {
    set sql "select distinct bboard.user_id, email, upper(email) as upper_email, count(bboard.user_id) as how_many_posts
from bboard, users 
where bboard.user_id = users.user_id
and topic_id = $topic_id
and posting_time >= to_date('$start_date','YYYY-MM-DD')
and posting_time <= to_date('$end_date','YYYY-MM-DD')
group by bboard.user_id, email
having count(*) >= $n_postings
order by upper_email"
}

set selection [ns_db select $db $sql]

set last_upper_email ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $last_upper_email == $upper_email } {
	# we've already sent to this guy
	ns_write "<li>skipping $email because it looks like a capitalization variant of the the above address\n"	
    } else {
	if [catch { ns_sendmail $email $from_address $subject $message } errmsg] {
	    ns_write "Trouble sending to $email: $errmsg\n"
	} else {
	    ns_write "<li>sent to $email\n"
	}
    }
    set last_upper_email $upper_email
}

ns_write "</ul>

[bboard_footer]
"


