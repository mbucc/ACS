# /www/bbaord/admin-expired-threads.tcl
ad_page_contract {
    Displays expired threads

    @cvs-id admin-expired-threads.tcl,v 3.2.2.3 2000/09/22 01:36:44 kevin Exp
} {
    topic
    topic_id:notnull,integer
}

# -----------------------------------------------------------------------------

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

append page_content "
[bboard_header "Expired threads in $topic"]

<h2>Expired Threads</h2>

in the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>

<ul>
"

db_foreach expired_threads "
select to_char(posting_time,'YYYY-MM-DD') as posting_date, 
       msg_id, 
       one_line, 
       sort_key, 
       email, 
       first_names || ' ' || last_name as name, 
       interest_level
from   bboard, users 
where  bboard.user_id = users.user_id
and    topic_id = :topic_id
and    (posting_time + expiration_days) < sysdate
and    refers_to is null
order by sort_key $q_and_a_sort_order" {

    append page_content "<li>$posting_date:  <a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg?msg_id=$msg_id\">$one_line</a>
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	append page_content " -- interest level $interest_level"
    }
} if_no_rows {
    append page_content "there are no expired threads right now"
}

append page_content "

</ul>

The only thing that you can do with these is <a
href=\"admin-expired-threads-delete.tcl?[export_url_vars topic topic_id]\">nuke them all</a>.  If you
want to preserve a thread, click on it and reset its expiration days
to be blank and/or enough to take it off this list.

[bboard_footer]
"

doc_return  200 text/html $page_content