# $Id: admin-community-view.tcl,v 3.0 2000/02/06 03:32:43 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables


# topic, topic_id, n_postings, hairy AOLserver widgets for start_date, end_date

# pull out start_date, end_date (ANSI format that will make Oracle hurl)

ns_dbformvalue [ns_conn form] start_date date start_date
ns_dbformvalue [ns_conn form] end_date date end_date



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
<title>Participants in $topic forum</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Participants in $topic forum</h2>

(<a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">main admin page</a>)

<hr>

Here are the participants who've made at least $n_postings postings
between $start_date and $end_date...

<ul>

"

if { $n_postings < 2 } {
    set sql "select distinct email, count(*) as how_many_posts
from bboard , users
where bboard.user_id = users.user_id
and topic_id = $topic_id
and posting_time >= to_date('$start_date','YYYY-MM-DD')
and posting_time <= to_date('$end_date','YYYY-MM-DD')
group by email
order by upper(email)"
} else {
    set sql "select distinct email, count(*) as how_many_posts
from bboard, users 
where topic_id = $topic_id
and posting_time >= to_date('$start_date','YYYY-MM-DD')
and posting_time <= to_date('$end_date','YYYY-MM-DD')
and bboard.user_id = users.user_id
group by email
having count(*) >= $n_postings
order by upper(email)"
}

set selection [ns_db select $db $sql]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"admin-view-one-email.tcl?[export_url_vars email topic topic_id]\">$email</a> ($how_many_posts)\n"
}

ns_write "</ul>

<p>

<h3>Spam</h3>

You can send them all an email message...

<form method=post action=admin-community-spam.tcl>
[export_form_vars topic topic_id start_date end_date n_postings]

From address:  <input name=from_address type=text size=30 value=\"$maintainer_email\">

<P>

Subject Line:  <input name=subject type=text size=50>

<P>

Message:

<textarea name=message rows=10 cols=80 wrap=hard>
</textarea>
<p>
<center>
<input type=submit value=\"Send Mail to these Folks\">
</center>
</form>

<h3>Contest</h3>

In case you are giving away prizes to people who participate in this
forum, we've provided the following random choice software.  It will
select at random N of the above users.

<p>

<form method=post action=admin-community-pick.tcl>
[export_form_vars topic topic_id start_date end_date n_postings]

How many winners:  <input name=n_winners type=text size=13>
<p>
<center>
<input type=submit>
</center>
</form>

[bboard_footer]
"
