# admin-community-view.tcl

ad_page_contract {
    @cvs-id  admin-community-view.tcl,v 3.1.6.6 2001/01/15 19:30:30 kevin Exp
} {
    topic
    topic_id:integer
    n_postings:integer
    start_date:date,array
    end_date:date,array
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}


append doc_body "<html>
<head>
<title>Participants in $topic forum</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Participants in $topic forum</h2>

(<a href=\"admin-home?[export_url_vars topic topic_id]\">main admin page</a>)

<hr>

Here are the participants who've made at least $n_postings postings
between $start_date(date) and $end_date(date) ...

<ul>

"

set ora_start $start_date(date)
set ora_end   $end_date(date)

if { $n_postings < 2 } {
    set sql "select distinct email, count(*) as how_many_posts
    from bboard , users
    where bboard.user_id = users.user_id
    and topic_id = :topic_id
    and posting_time >= to_date(:ora_start,'YYYY-MM-DD')
    and trunc(posting_time) <= to_date(:ora_end,'YYYY-MM-DD')
    group by email
    order by upper(email)"

} else {
    set sql "select distinct email, count(*) as how_many_posts
    from bboard, users 
    where topic_id = :topic_id
    and posting_time >= to_date(:ora_start,'YYYY-MM-DD')
    and trunc(posting_time) <= to_date(:ora_end,'YYYY-MM-DD')
    and bboard.user_id = users.user_id
    group by email
    having count(*) >= :n_postings
    order by upper(email)"

}

db_foreach posters $sql {
    append doc_body "<li><a href=\"admin-view-one-email?[export_url_vars email topic topic_id]\">$email</a> ($how_many_posts)\n"
}

set start_date.year  $start_date(year)
set start_date.month $start_date(month)
set start_date.day   $start_date(day)
set end_date.year    $end_date(year)
set end_date.month   $end_date(month)
set end_date.day     $end_date(day)


append doc_body "</ul>
<p>

<h3>Spam</h3>

You can send them all an email message...

<form method=post action=admin-community-spam>
[export_form_vars topic topic_id start_date.year start_date.month \
	start_date.day end_date.year end_date.month end_date.day n_postings]

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

<form method=post action=admin-community-pick>
[export_form_vars topic topic_id start_date.year start_date.month \
	start_date.day end_date.year end_date.month end_date.day n_postings]

How many winners:  <input name=n_winners type=text size=13>
<p>
<center>
<input type=submit>
</center>
</form>

[bboard_footer]
"


doc_return  200 text/html $doc_body
