# /www/bboard/admin-q-and-a-unanswered.tcl
ad_page_contract {
    Show unanswered questions

    @param topic the name of the bboard topic

    @cvs-id admin-q-and-a-unanswered.tcl,v 3.2.2.3 2000/09/22 01:36:46 kevin Exp
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
[bboard_header "$topic Unanswered Questions"]

<h2>Unanswered Questions</h2>

in the <a href=\"admin-q-and-a?[export_url_vars topic topic_id]\">$topic Q&A forum</a>

<hr>

<ul>
"

# we want only top level questions that have no answers

db_foreach messages "
select msg_id, 
       one_line, 
       sort_key,  
       email, 
       first_names || ' ' || last_name as name,  
       interest_level
from   bboard bbd1, 
       users
where  topic_id = :topic_id
and    bbd1.user_id = users.user_id
and    0 = (select count(*) from bboard bbd2 
            where bbd2.refers_to = bbd1.msg_id)
and    refers_to is null
order by sort_key $q_and_a_sort_order" {

    append page_content "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg?msg_id=$msg_id\">$one_line</a>
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	append page_content " -- interest level $interest_level"
    }
}

append page_content "

</ul>

[bboard_footer]
"

doc_return  200 text/html $page_content