# /www/bboard/q-and-a-unanswered.tcl

ad_page_contract {
    returns a listing of the threads that haven't been answered,
    sorted by descending date
    q-and-a-unanswered
    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1995
    @cvs-id q-and-a-unanswered.tcl,v 3.0.12.5 2000/09/22 01:36:53 kevin Exp
} {
    topic_id:integer
}

if {[bboard_get_topic_info] == -1} {
    return
}

set page_content "[bboard_header "$topic Unanswered Questions"]

<h2>Unanswered Questions</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Unanswered Questions"]

<hr>

<ul>
"

# we want only top level questions that have no answers

set selection [ns_set create]
db_foreach message "
         select urgent_p, 
                msg_id, 
                one_line, 
                sort_key, 
                posting_time,
                bbd1.user_id as poster_id,
                users.email, 
                users.first_names || ' ' || users.last_name as name
         from   bboard bbd1,
                users 
         where  bbd1.user_id = users.user_id
         and    topic_id = :topic_id
         and    0 = (select count(*) 
                     from   bboard bbd2
                     where  bbd2.refers_to = bbd1.msg_id)
         and refers_to is null
         order by sort_key $q_and_a_sort_order" -column_set selection {

    set msg_id [ns_set get $selection msg_id]
    set one_line [ns_set get $selection one_line]

    append page_content "<li><a href=\"[bboard_msg_url $presentation_type $msg_id $topic]\">$one_line</a> [bboard_one_line_suffix $selection $subject_line_suffix]\n"

}

append page_content "

</ul>

[bboard_footer]
"



doc_return  200 text/html $page_content










