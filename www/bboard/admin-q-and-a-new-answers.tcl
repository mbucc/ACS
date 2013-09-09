# /www/bboard/admin-q-and-a-new-answers.tcl
ad_page_contract {
    @cvs_id admin-q-and-a-new-answers.tcl,v 3.2.2.3 2000/09/22 01:36:45 kevin Exp
} {
    topic:notnull
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

append page_content "
[bboard_header "$topic Recent Answers"]

<h2>Recent Answers</h2>

in the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic Q&A forum</a>

<hr>

<ul>
"

db_foreach new_answers "
select bnah.root_msg_id,
       count(*) as n_new,
       max(bnah.posting_time) as max_posting_time, 
       to_char(max(bnah.posting_time),'YYYY-MM-DD') as max_posting_date, 
       bboard.one_line as subject_line
from   bboard_new_answers_helper bnah, 
       bboard
where  bnah.posting_time > sysdate - 7
and    bnah.root_msg_id = bboard.msg_id
and    bnah.topic_id = :topic_id
group by root_msg_id, bboard.one_line
order by max_posting_time desc" {

    if { $n_new == 1 } {
	set answer_phrase "answer, "
    } else {
	set answer_phrase "answers, last "
    }
    append page_content "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg?msg_id=$root_msg_id\">$subject_line</a> ($n_new new $answer_phrase on [util_IllustraDatetoPrettyDate $max_posting_date])"

}

append page_content "

</ul>

[bboard_footer]
"


doc_return  200 text/html $page_content
