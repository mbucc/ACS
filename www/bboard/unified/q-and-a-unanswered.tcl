# /www/bboard/unified/q-and-a-unanswered.tcl
ad_page_contract {
    returns a listing of the threads that haven't been answered,
    sorted by descending date
  
    @author philg@mit.edu
    @author LuisRodriguez@photo.net 
    @creation-date 1995
    @cvs-id q-and-a-unanswered.tcl,v 1.2.2.6 2000/09/22 01:37:00 kevin Exp
} {
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

set topics_in_user_default [db_string user_topics "
SELECT count(*)
FROM bboard_unified
WHERE user_id = :user_id"]

if { $user_id == 0 || $topics_in_user_default == 0 } {
    set topic_id_sql "SELECT topic_id
             FROM bboard_topics
             WHERE default_topic_p = 't'
            "
    set color_icon_select "bboard_topics.color AS color,
                           NVL(bboard_topics.icon_id,-1) AS icon_id"
    set table_for_view_params "bboard_topics"
    set bboard_unified_topic_id_sql ""

} else {
    set topic_id_sql "SELECT topic_id
             FROM bboard_unified
             WHERE default_topic_p = 't'
             AND   user_id = :user_id
    "
    set color_icon_select "bboard_unified.color AS color,
                           NVL(bboard_unified.icon_id,-1) AS icon_id"
    set table_for_view_params ", bboard_unified"
    set bboard_unified_topic_id_sql "AND bboard_unified.user_id = :user_id
                                     AND bboard_unified.topic_id = bbd1.topic_id"
}

set topic_id_list [db_list user_topic_list $topic_id_sql]

# we want only top level questions that have no answers

db_foreach unanswered_questions "
SELECT bbd1.urgent_p AS urgent_p, 
       msg_id, 
       one_line, 
       sort_key, 
       posting_time, 
       bbd1.user_id as poster_id, 
       users.email,  
       users.first_names || ' ' || users.last_name as name, 
       bboard_topics.topic AS topic, 
       presentation_type, 
       subject_line_suffix, 
       bbd1.topic_id AS topic_id,
       $color_icon_select
FROM bboard bbd1, users, bboard_topics $table_for_view_params
WHERE bbd1.user_id = users.user_id
  AND bboard_topics.topic_id = bbd1.topic_id
  AND bbd1.topic_id IN ($topic_id_sql)
  AND 0 = (select count(*) from bboard bbd2 where bbd2.refers_to = bbd1.msg_id)
  AND refers_to is null
  $bboard_unified_topic_id_sql
ORDER BY posting_time DESC" {

    set color_vars [ad_tcl_vars_to_ns_set posting_time urgent_p \
	    topic_id msg_id poster_id name email]
  
    set text_color "$color"

    if { $icon_id > 0 } {
	set icon_img [util_memoize "icon_id_to_img_html $icon_id" 3600]
    } else {
	set icon_img ""
    }

    append rest_of_page "<li> $icon_img <font color=\"$text_color\"> 
<a style=\"color:$text_color\" href=\"/bboard/[bboard_msg_url $presentation_type $msg_id $topic_id $topic]\">$one_line</a> 
[bboard_one_line_suffix_color $color_vars $subject_line_suffix $text_color] 
</font> <font size='-2'>
<a style=\"color:$text_color\" href=\"/bboard/q-and-a?[export_url_vars topic_id topic]\">($topic)</a> </font>\n"
}

db_release_unused_handles

set page_content "[bboard_header "$topic Unanswered Questions"]

<h2>Unanswered Questions</h2>

[ad_context_bar_ws_or_index [list "index" [bboard_system_name]] [list "/bboard/unified/" "View Personalized Forums"] "Unanswered Questions"]

<hr>

<ul>
$rest_of_page
</ul>

[bboard_footer]
"

doc_return  200 text/html $page_content
