# /www/bboard/unified/q-and-a-new-answers.tcl
ad_page_contract {
    this will either display answers new since a last visit or 
    simply ones new within the last week (if there is no obvious last visit)

    @author philg@mit.edu
    @author LuisRodriguez@photo.net
    @creation-date 1995
    @cvs-id q-and-a-new-answers.tcl,v 1.2.2.4 2000/09/22 01:37:00 kevin Exp
} {}

# -----------------------------------------------------------------------------
 
set user_id [ad_verify_and_get_user_id]

set second_to_last_visit [ad_get_cookie second_to_last_visit ""]

if [empty_string_p $second_to_last_visit] {
    set title "postings in the last seven days"
    set explanation ""
    set query_time_limit "sysdate - 7"
} else {
    set title "postings since your last visit"
    set explanation "These are discussions in which there has been a contribution since your last visit, which we think was [ns_fmttime $second_to_last_visit "%x %X %Z"]"
    set query_time_limit "to_date('[ns_fmttime $second_to_last_visit "%Y-%m-%d %H:%M:%S"]','YYYY-MM-DD HH24:MI:SS')"
}

set topics_in_user_default [db_string num_user_topics "
SELECT count(*)
FROM bboard_unified
WHERE user_id = :user_id"]

if { $user_id == 0 || $topics_in_user_default == 0 } {
    set topic_id_sql "SELECT topic_id
             FROM bboard_topics
             WHERE default_topic_p = 't'
            "
    set table_for_view_params ""
    set bboard_unified_topic_id_sql ""
    set color_icon_group  "bboard_topics.color,
                           NVL(bboard_topics.icon_id,-1)"
    set color_icon_select "bboard_topics.color AS color,
                           NVL(bboard_topics.icon_id,-1) AS icon_id"
} else {
    set topic_id_sql "SELECT topic_id
             FROM bboard_unified
             WHERE default_topic_p = 't'
             AND   user_id = :user_id
    "
    set color_icon_select "bboard_unified.color AS color,
                           NVL(bboard_unified.icon_id,-1) AS icon_id"
    set color_icon_group  "bboard_unified.color,
                           NVL(bboard_unified.icon_id,-1)"
    set table_for_view_params ", bboard_unified"
    set bboard_unified_topic_id_sql "AND bboard_unified.user_id = :user_id
                                     AND bboard_unified.topic_id = bnah.topic_id"
}

set topic_id_list [db_list topic_id_list $topic_id_sql]

# Might need to break this apart into two queries, because of the GROUP BY

db_foreach get_new_answers "
SELECT bnah.root_msg_id, count(*) as n_new,
                max(bnah.posting_time) as max_posting_time,
                to_char(max(bnah.posting_time),'YYYY-MM-DD') as max_posting_date, 
                bboard.one_line as subject_line,
                bboard_topics.topic AS topic, 
                max(bnah.topic_id) AS topic_id, 
                presentation_type, subject_line_suffix,
                $color_icon_select
         FROM bboard_new_answers_helper bnah, bboard, bboard_topics $table_for_view_params
         WHERE bnah.posting_time >  $query_time_limit
         AND bboard.topic_id = bboard_topics.topic_id
         $bboard_unified_topic_id_sql
         AND bnah.root_msg_id = bboard.msg_id
         AND bnah.topic_id IN ($topic_id_sql)
         GROUP BY root_msg_id, bboard.one_line, 
                  bboard_topics.topic, 
                  presentation_type, subject_line_suffix, 
                  $color_icon_group
         ORDER BY max_posting_time DESC
" {

    if { $n_new == 1 } {
	set answer_phrase "answer, "
    } else {
	set answer_phrase "answers, last "
    }

    if { ![empty_string_p $color] } {
	set text_color "$color"
    } else {
	set text_color ""
    }

    if { $icon_id > 0 } {
	set icon_img [util_memoize "icon_id_to_img_html $icon_id" 3600]
    } else {
	set icon_img ""
    }

    append rest_of_page "<li>$icon_img <a style=\"color:$text_color\" href=\"/bboard/[bboard_msg_url $presentation_type $root_msg_id $topic_id $topic]\">$subject_line</a> <font color=\"$text_color\">($n_new new $answer_phrase on [util_AnsiDatetoPrettyDate $max_posting_date])</font> <font size='-2'><a style=\"color:$text_color\" href=\"/bboard/q-and-a?[export_url_vars topic_id topic]\">($topic)</a> </font>\n"

} if_no_rows {
    append rest_of_page "<li>... it seems that there haven't been any new responses." 
}

db_release_unused_handles

set page_content "[bboard_header "Forum New Answers $title"]

<h2>$title</h2>

[ad_context_bar_ws_or_index [list "index" [bboard_system_name]] [list "/bboard/unified/" "View Personalized Forums"] "New Postings"]

<hr>

$explanation

<ul>
$rest_of_page
</ul>

[bboard_footer]
"

doc_return  200 text/html $page_content
