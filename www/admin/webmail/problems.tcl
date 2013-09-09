# /admin/webmail/problems.tcl

ad_page_contract {
    Deal with common webmail problems.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-04-03
    @cvs-id problems.tcl,v 1.4.2.4 2000/09/22 01:36:39 kevin Exp
} {}
    

## Parse Errors
set parse_errors ""

db_foreach errors {
    select filename, error_message, to_char(first_parse_attempt, 'YYYY-MM-DD HH24:MI:SS') as pretty_parse_attempt_date
    from wm_parse_errors
    order by first_parse_attempt
} {
    append parse_errors "<li>$filename ($pretty_parse_attempt_date)<br>\n<pre>\n$error_message\n</pre>\n"
} if_no_rows {
    set parse_errors "<li>No parse errors\n"
}

## Repeated Messages
set repeated_messages ""

db_foreach repeated_msgs {
    select count(*) as n_messages, value as subject, message_id
    from wm_messages m, wm_headers h
    where m.msg_id = h.msg_id
    and m.message_id is not null
    and h.lower_name(+) = 'subject'
    group by m.message_id, value
    having count(*) > 50
    order by 1 desc
} {
    append repeated_messages "<li>$n_messages: $subject <font size=-1>\[ <a href=\"repeated-message-cleanup?[export_url_vars message_id]\">clean up</a> \]</font>\n"
} if_no_rows {
    set repeated_messages "<li>No repeated messages\n"
}

## Broken Jobs

set broken_jobs ""

db_foreach broken_jobs {
    select job, what
    from user_jobs
    where broken = 'Y'
} {
    append broken_jobs "<li>$what <font size=-1>\[ <a href=\"job-restart?[export_url_vars job]\">Restart</a> \]</font>\n"
} if_no_rows {
    set broken_jobs "<li>No broken jobs\n"
}

## Unassigned messages

set unassigned_messages ""

db_foreach unassigned {
    select m.msg_id, f.value as author, s.value as subject, t.value as recipient, count(*) as n_msgs
    from wm_messages m, wm_headers f, wm_headers s, wm_headers t
    where m.msg_id = f.msg_id(+)
    and m.msg_id = s.msg_id(+)
    and m.msg_id = t.msg_id(+)
    and f.lower_name = 'from'
    and s.lower_name = 'subject'
    and t.lower_name = 'to'
    and m.msg_id not in (select distinct msg_id from wm_message_mailbox_map)
    group by m.msg_id, f.value, s.value, t.value
    order by author, subject, recipient
} {
    append unassigned_messages "<li>$n_msgs from $author to $recipient, \"$subject\"\n"
}



doc_return  200 text/html "[ad_admin_header "Common WebMail Problems"]
<h2>Common Webmail Problems</h2>

 [ad_admin_context_bar [list "index.tcl" "WebMail Admin"] "Common Problems"]

<hr>

<h3>Parse Errors</h3>

<ul>
$parse_errors
</ul>

<p>

<a href=\"parse-errors-delete\">delete all errors</a>

<h3>Repeated Messages</h3>

In the first release of the WebMail parsing routines, a message that had a 
parse error would continually be inserted into the database, resulting in
many repeated messages. This section lists the subject lines for which there
are more than 50 messages with the same Message-ID field.
Clicking \"clean up\" will remove all but one of them for
each recipient which received it.

<ul>
$repeated_messages
</ul>

<h3>Broken Jobs</h3>

If a dbms_job fails to execute enough times, it will be marked as \"broken\" 
and not run again.

<ul>
$broken_jobs
</ul>

<h3>Unassigned Messages</h3>

These are messages which were delivered but unassigned to any user for 
some reason.

<ul>
$unassigned_messages
</ul>

[ad_admin_footer]
"
