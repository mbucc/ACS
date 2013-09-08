# /www/bboard/admin-community-spam.tcl
ad_page_contract {
    Spams a portion of the bboard community

    @param topic bboard topic to restrict spam to
    @param start-date date to restrict by
    @param end_date date to restrict by
    @param message the spam
    @param from_address who is is coming from
    @param subject subject line for the email

    @cvs-id admin-community-spam.tcl,v 3.1.6.4 2000/09/22 01:36:43 kevin Exp
} {
    topic:notnull
    n_postings:notnull,integer
    start_date:date,array
    end_date:date,array
    from_address:notnull
    subject:notnull
    message:notnull
}

# -----------------------------------------------------------------------------

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}


append page_content "
[bboard_header "Spamming participants in $topic forum"]

<h2>Spamming participants in $topic forum</h2>

(<a href=\"admin-home?[export_url_vars topic topic_id]\">main admin page</a>)

<hr>

Proceeding to spam the participants who've made at least $n_postings
postings between $start_date(date) and $end_date(date) ...

<pre>
From: $from_address
Subject: $subject
---- body ---
$message
</pre>

<ul>

"

set ora_start $start_date(date)
set ora_end   $end_date(date)

if { $n_postings < 2 } {
    set sql "
    select distinct bboard.user_id,  
           count(bboard.user_id) as how_many_posts, 
           upper(email) as upper_email,email
    from   bboard, users
    where  bboard.user_id = users.user_id 
    and    topic_id = :topic_id
    and    posting_time >= to_date(:ora_start,'YYYY-MM-DD')
    and    posting_time <= to_date(:ora_end,'YYYY-MM-DD')
    group by bboard.user_id, email
    order by upper_email"
} else {
    set sql "
    select distinct bboard.user_id, 
           email, 
           upper(email) as upper_email, 
           count(bboard.user_id) as how_many_posts
    from   bboard, users 
    where  bboard.user_id = users.user_id
    and    topic_id = :topic_id
    and    posting_time >= to_date(:ora_start,'YYYY-MM-DD')
    and    posting_time <= to_date(:ora_end,'YYYY-MM-DD')
    group by bboard.user_id, email
    having count(*) >= :n_postings
    order by upper_email"
}

set last_upper_email ""

db_foreach users $sql {

    if { $last_upper_email == $upper_email } {
	# we've already sent to this guy
	append page_content "<li>skipping $email because it looks like a capitalization variant of the the above address\n"	
    } else {
	if [catch { ns_sendmail $email $from_address $subject $message } errmsg] {
	    append page_content "Trouble sending to $email: $errmsg\n"
	} else {
	    append page_content "<li>sent to $email\n"
	}
    }
    set last_upper_email $upper_email
}

append page_content "</ul>

[bboard_footer]
"

doc_return  200 text/html $page_content

