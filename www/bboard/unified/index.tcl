# /www/bboard/unified/index.tcl
ad_page_contract {
    top-level page showing postings from many different forums

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id index.tcl,v 1.1.4.5 2000/09/22 01:36:59 kevin Exp
} {
}

# -----------------------------------------------------------------------------

set user_id [ad_get_user_id]

set menubar_options [list]

lappend menubar_options "<a href=\"q-and-a-post-new\">Ask new question</a>"

if { [bboard_pls_blade_installed_p] } {
    lappend menubar_options "<a href=\"q-and-a-search-form\">Search</a>"
}

lappend menubar_options "<a href=\"q-and-a-unanswered\">Unanswered Questions</a>"

lappend menubar_options "<a href=\"q-and-a-new-answers\">New Answers</a>"

lappend menubar_options "<a href=\"personalize\">Personalize</a>"

set first_part_of_page "[bboard_header "Unified Forum Top Level"]

<h2>Unified Forum</h2>

[ad_context_bar_ws_or_index [list "/bboard/index" [bboard_system_name]] "Unified Forum"]

<hr>
"

if { $user_id == 0 } {
    set table_for_view_params ""
    set color_icon_select "bboard_topics.color AS color,
                           NVL(bboard_topics.icon_id,-1) AS icon_id"
    set bboard_unified_topic_id_sql "AND bboard_topics.default_topic_p = 't'
                                     AND bboard_topics.read_access IN ('any')"
} else {

    # **** Ideally, this should be called once, at login
    # **** This call ensure that the user has access to any new forums and that the 
    # **** user's access to any forums that he/she no longer has permission to access
    # **** is not compromized by this script
    # **** Remove this once ACS is upgraded (e.g., ACS 3.3)
    update_user_unified_topics $user_id
    
    set table_for_view_params ", bboard_unified"
    set color_icon_select "bboard_unified.color AS color,
                           NVL(bboard_unified.icon_id,-1) AS icon_id"
    set bboard_unified_topic_id_sql "AND bboard_unified.user_id = :user_id
                                     AND bboard_unified.topic_id = bboard.topic_id
                                     AND bboard_unified.default_topic_p = 't'"
}

set new_posts ""

db_foreach messages_and_topics "
SELECT DISTINCT 
       msg_id, 
       one_line, 
       bboard_topics.topic AS topic, 
       bboard.topic_id AS topic_id, 
       presentation_type, 
       subject_line_suffix, 
       posting_time, 
       first_names || ' ' || last_name as name, 
       email,
       TO_CHAR (posting_time, 'Mon DD') AS pretty_posting_time, 
       bboard.user_id AS poster_id, 
       urgent_p,
       $color_icon_select 
FROM   bboard, users, bboard_topics $table_for_view_params 
WHERE  bboard_topics.topic_id = bboard.topic_id 
AND    bboard.user_id = users.user_id 
AND    refers_to IS NULL 
AND    posting_time > (sysdate - bboard_topics.q_and_a_new_days) 
$bboard_unified_topic_id_sql 
ORDER BY posting_time DESC 
" {

    set color_vars [ad_tcl_vars_to_ns_set posting_time urgent_p \
	    topic_id msg_id poster_id name email]

    set text_color "$color"

    if { $icon_id > 0 } {
	set icon_img [util_memoize "icon_id_to_img_html $icon_id" 3600]
    } else {
	set icon_img ""
    }

    append new_posts "<li> <font color=\"$text_color\"> $icon_img <a style=\"color:$text_color\" href=\"/bboard/[bboard_msg_url $presentation_type $msg_id $topic_id $topic]\">$one_line</a> [bboard_one_line_suffix_color $color_vars $subject_line_suffix $text_color] </font> <font size='-2'><a style=\"color:$text_color\" href=\"/bboard/q-and-a?[export_url_vars topic_id topic]\">($topic)</a> </font>\n"

    ns_set free $color_vars
}

set topic_menu_html ""

db_foreach topics_and_prefs "
SELECT DISTINCT bboard_topics.topic AS topic, 
 bboard.topic_id AS topic_id, 
 q_and_a_show_cats_only_p, 
 q_and_a_categorized_p, 
 $color_icon_select 
 FROM bboard, users, bboard_topics $table_for_view_params 
 WHERE bboard_topics.topic_id = bboard.topic_id 
 AND bboard.user_id = users.user_id 
 AND refers_to IS NULL 
 $bboard_unified_topic_id_sql 
 ORDER BY topic 
" {

    if { $q_and_a_categorized_p == "t" && $q_and_a_show_cats_only_p == "t" } {
	append topic_menu_html "<li><a style=\"color:$color\" href=\"/bboard/unified/q-and-a-cat-only?[export_url_vars topic_id]\">$topic</a>"
    } else {
	append topic_menu_html "<li><a style=\"color:$color\" href=\"/bboard/q-and-a?[export_url_vars topic_id]\">$topic</a>"
    }
}

db_release_unused_handles 

set whole_page "

$first_part_of_page

<table cellspacing=10> 
<tr> <td> 
\[ [join $menubar_options " | "] \]
</td>

<td>   </td> </tr> 

<tr>

<td valign=top> 
<ul>
$new_posts
</ul>
</td>

<td valign=top>
Older Messages:
<ul>
$topic_menu_html
</ul></td>

</tr>

</table>

[bboard_footer]
"

doc_return  200 text/html "$whole_page"



