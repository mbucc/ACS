# /www/bboard/contributions.tcl
ad_page_contract {
    Finds bboard contributions from a user

    @param user_id the ID of the user we are looking at

    @cvs-id contributions.tcl,v 3.2.2.3 2000/09/22 01:36:49 kevin Exp
} {
    user_id:integer,notnull
}

# -----------------------------------------------------------------------------

set current_user_id [ad_verify_and_get_user_id]

# displays the contibutions of this member to the bboard

if {![db_0or1row user_info "
select first_names, last_name from users where user_id = :user_id"] } {

    doc_return  200 text/html "can't figure this user in the database"
    return
}

append page_content "
[bboard_header "$first_names $last_name"]

<h2>$first_names $last_name</h2> 

as a contributor to <A HREF=\"/bboard/\">the discussion forums</a> in 
<a href=/>[ad_system_name]</a>
<hr>

<ul>
"

db_foreach user_postings "
select one_line, 
       msg_id,  
       posting_time, 
       sort_key, 
       bboard_topics.topic, 
       bboard_topics.topic_id, 
       presentation_type 
from   bboard, 
       bboard_topics 
where  bboard.user_id = :user_id
and    bboard.topic_id = bboard_topics.topic_id
and    bboard_user_can_view_topic_p(:current_user_id,bboard.topic_id)='t'
order by posting_time asc" {

    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    append page_content "<li>[util_IllustraDatetoPrettyDate $posting_time]: <a href=\"/bboard/[bboard_msg_url $presentation_type $thread_start_msg_id $topic_id $topic]\">$one_line</a>\n"

} if_no_rows {
    append page_content "no contributions found"
}
    
append page_content "
</ul>
   
[bboard_footer]
"

doc_return 200 text/html $page_content
