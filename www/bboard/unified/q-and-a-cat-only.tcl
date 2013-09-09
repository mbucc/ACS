# /www/bboard/unified/q-and-a-cat-only.tcl
ad_page_contract {
    View messages for one topic

    @param topic_id the ID of the bboard topic

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id q-and-a-cat-only.tcl,v 1.1.4.4 2000/09/22 01:36:59 kevin Exp
} {
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

if { [bboard_pls_blade_installed_p] } {
    lappend menubar_options "<a href=\"/bboard/q-and-a-search-form?[export_url_vars topic_id]\">Search</a>"
}

if { $user_id == 0 } {
    set table_for_view_params ""
    set bboard_unified_topic_id_sql "AND bboard_topics.default_topic_p = 't'"
} else {
    set table_for_view_params ", bboard_unified"
    set bboard_unified_topic_id_sql "AND bboard_unified.user_id = :user_id
                                     AND bboard_unified.topic_id = bboard.topic_id
                                     AND bboard_unified.default_topic_p = 't'"
}

db_foreach user_topics "
SELECT DISTINCT bboard_topics.topic AS topic,
                q_and_a_show_cats_only_p,
                q_and_a_categorized_p
FROM bboard, users, bboard_topics $table_for_view_params
WHERE bboard_topics.topic_id = bboard.topic_id
  AND bboard.user_id = users.user_id
  AND refers_to IS NULL
  AND bboard.topic_id = :topic_id
  $bboard_unified_topic_id_sql
ORDER BY topic
" {

    if { $q_and_a_categorized_p == "t" } {
	if { $q_and_a_show_cats_only_p == "t" } {
	    append cat_posts "<ul>\n"
	    # this is a safe operation because $topic has already been verified to exist
	    # in the database (i.e., it won't contain anything naughty for the eval in memoize)
	    append cat_posts [util_memoize "bboard_compute_categories_with_count $topic_id" 300]
	    append cat_posts "<P>
	    <li><a href=\"/bboard/q-and-a-one-category?[export_url_vars topic_id topic]&category=uncategorized\">Uncategorized</a>
	    </ul>"
	} else {
	    # let's assume there was at least one section
	    append cat_posts "\n</ul>\n"
	}
	# done showing the extra stuff for categorized bboard
    }
    append whole_page "</ul>"
}
	

set menubar_options [list]
lappend menubar_options "<a href=\"/bboard/q-and-a-post-new?[export_url_vars topic_id]\">Ask new question</a>"

set page_content "

[bboard_header "Messages by Category"]

<h2>$topic <font size=-1>(by category)</font></h2>

[ad_context_bar_ws_or_index [list "/bboard/index" [bboard_system_name]] [list "/bboard/q-and-a?[export_url_vars topic_id]" $topic] "Messages by Category"]

<hr>

\[ [join $menubar_options " | "] \]
<br>

</ul>

$cat_posts

[bboard_footer]
"

 

doc_return  200 text/html $page_content


