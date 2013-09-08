# /www/bboard/unified/display-view.tcl
ad_page_contract {
    Displays the topics in a view (pieces hacked from q-and-a.tcl)
  
    @author LuisRodriguez@photo.net
    @cvs-id display-view-1.tcl,v 1.2.2.4 2000/09/22 01:36:59 kevin Exp
} {
}

# -----------------------------------------------------------------------------

set menubar_options [list]

set user_id [ad_verify_and_get_user_id]

set topic_id_list [db_list topic_id_list "
SELECT DISTINCT 
       bboard_view.topic_id AS topic_id,
       UPPER(bboard_topics.topic) AS topic
FROM   bboard_view, bboard_topics
WHERE  user_id = :user_id
AND    bboard_topics.topic_id = bboard_view.topic_id
ORDER BY topic ASC"]

if { [bboard_pls_blade_installed_p] } {
    lappend menubar_options "<a href=\"q-and-a-search-form?[export_url_vars topic_id topic]\">Search</a>"
}

lappend menubar_options "<a href=\"q-and-a-unanswered?[export_url_vars topic_id topic]\">Unanswered Questions</a>"

lappend menubar_options "<a href=\"q-and-a-new-answers?[export_url_vars topic_id topic]\">New Answers</a>"

set first_part_of_page "[bboard_header "Personalized Forums Top Level"]

<h2>Personalized Forums</h2>

[ad_context_bar_ws_or_index [list "/bboard/index" [bboard_system_name]] [list "/bboard/unified/personalize" "Forum View Personalization"] "View Personalized Forums"]

<hr>

\[ [join $menubar_options " | "] \] <br>

"

set registered_categorized_p 'f'
set new_question ""
set rest_of_page ""
set new_posts ""

foreach topic_id $topic_id_list {
    # this procedure sets a bunch of stuff in this frame
    if { [bboard_get_topic_info] != -1 } {
	append $new_question "<OPTION value=\"$topic_id\">$topic</OPTION>"

	if { $registered_categorized_p == "f" && $q_and_a_categorized_p == "t" && (![info exists category_centric_p] || $category_centric_p == "f")} {
	    append rest_of_page "
	    <h3>New Questions</h3>
	    
	    
	    <ul>
	    
	    "
	    set registered_categorized_p 't'
	} else {
	    append rest_of_page "
	    
	    <ul>

	    "
	}

	# this is not currently used, moderation should be turned on with certain
	# moderation_policies in case we add more
	
	set approved_clause ""
	if { $q_and_a_categorized_p == "t" } {
	    set sql "select urgent_p, msg_id, one_line, sort_key, posting_time, 
	    email, first_names || ' ' || last_name as name, 
	    users.user_id as poster_id
	    from bboard, users 
	    where topic_id = :topic_id approved_clause
	    and bboard.user_id = users.user_id 
	    and refers_to is null
	    and posting_time > (sysdate - :q_and_a_new_days)
	    order by sort_key $q_and_a_sort_order"
	} elseif { [info exists custom_sort_key_p] && $custom_sort_key_p == "t" } {
	    set sql "select urgent_p, msg_id, one_line, sort_key, posting_time, 
	    email, first_names || ' ' || last_name as name, custom_sort_key, 
	    custom_sort_key_pretty, users.user_id as poster_id
	    from bboard, users
	    where topic_id = :topic_id $approved_clause
	    and refers_to is null
	    and bboard.user_id = users.user_id 
	    order by custom_sort_key $custom_sort_order" 
	} else {
	    set sql "select urgent_p, msg_id, one_line, sort_key, posting_time, 
	    email, first_names || ' ' || last_name as name, 
	    users.user_id as poster_id
	    from bboard, users
	    where topic_id = :topic_id $approved_clause
	    and bboard.user_id = users.user_id
	    and refers_to is null
	    order by sort_key $q_and_a_sort_order
	    "
	}

	if { ![info exists category_centric_p] || $category_centric_p == "f" } {
	    # we're not only doing categories
	    db_foreach messages $sql {
		
		if { [info exists custom_sort_key_p] && $custom_sort_key_p == "t" } {
		    if { $custom_sort_key_pretty != "" } {
			set prefix "${custom_sort_key_pretty}: "
		    } elseif { $custom_sort_key != "" } {
			set prefix "${custom_sort_key}: "
		    } else {
			set prefix ""
		    }
		    append new_posts "<tr> <td> <a href=\"/bboard/q-and-a?[export_url_vars topic_id topic]\">$topic</a> </td> <td>${prefix}<a href=\"/bboard/[bboard_msg_url $presentation_type $msg_id $topic_id $topic]\">$one_line</a> [bboard_one_line_suffix $selection $subject_line_suffix]</td></tr>\n"
		} else {
		    append new_posts "<tr> <td><a href=\"/bboard/q-and-a?[export_url_vars topic_id topic]\">$topic</a> </td> <td> <a href=\"/bboard/[bboard_msg_url $presentation_type $msg_id $topic_id $topic]\">$one_line</a> [bboard_one_line_suffix $selection $subject_line_suffix]</td> </tr>\n"
		}
		
	    }
	}
	
	if { $q_and_a_categorized_p == "t" } {
	    if { $q_and_a_show_cats_only_p == "t" } {
		append cat_posts "<h3>Older Messages (by category) in <a href=\"/bboard/q-and-a?[export_url_vars topic_id topic]\">$topic</a> forum</h3>\n\n<ul>\n"
		# this is a safe operation because $topic has already been verified to exist
		# in the database (i.e., it won't contain anything naughty for the eval in memoize)
		append cat_posts [util_memoize "bboard_compute_categories_with_count $topic_id" 300]
		append cat_posts "<P>
		<li><a href=\"/bboard/q-and-a-one-category?[export_url_vars topic_id topic]&category=uncategorized\">Uncategorized</a>
		</ul>"
	    } elseif { [info exists category_centric_p] && $category_centric_p == "t" } {
		# this is for 6.001 forums where every message must be under
		# a category
		set sql "select category from
		bboard_q_and_a_categories
		where topic_id = :topic_id
		order by 1"
		append cat_posts "<ul>"
		db_foreach categories $sql {
		    
		    append cat_posts "<li>$topic<a href=\"/bboard/cc?[export_url_vars topic_id topic]&key=[ns_urlencode $category]\">$category</a>\n"
		} if_no_rows {
		    append cat_posts "nobody is using this forum yet"
		}
		append cat_posts "</ul>"
	    } else {
		# we now have to present the older messages
		# (if uncategorized, the query above was enough to get everything)
		if { $q_and_a_use_interest_level_p == "t" } {
		    set interest_clause "and (interest_level is NULL or interest_level >= [bboard_interest_level_threshold])\n"
		} else {
		    # not restricting by interest level
		    set interest_clause ""
		}
		set sql "select msg_id, one_line, sort_key, posting_time, email, 
		first_names || ' ' || last_name as name, category, 
		decode(category,null,'t','','t','f') as uncategorized_p, 
		users.user_id as poster_id  
		from bboard, users 
		where topic_id = :topic_id
		and bboard.user_id = users.user_id
		and refers_to is null
		$interest_clause
		and posting_time <= (sysdate - $q_and_a_new_days)
		order by uncategorized_p, category, sort_key $q_and_a_sort_order"
		
		set last_category "there ain't no stinkin' category with this name"
		set first_category_flag 1
		
		db_foreach messages $sql {
		    
		    if { $category != $last_category } {
			set last_category $category
			if { $first_category_flag != 1 } {
			    # we have to close out a <ul>
			    append cat_posts "\n</ul>\n"
			} else {
			    set first_category_flag 0
			}
			if { $category == "" } {
			    set pretty_category "Uncategorized"
			} else {
			    set pretty_category $category
			}
			append cat_posts "<h3>$pretty_category</h3>
			
			<ul>
			"
		    }
		    
		    append cat_posts "<li><a href=\"/bboard/[bboard_msg_url $presentation_type $msg_id $topic_id $topic]\">$one_line</a> [bboard_one_line_suffix $selection $subject_line_suffix]\n"
		}
		
		# let's assume there was at least one section
		
		append cat_posts "\n</ul>\n"
		
	    }
	    # done showing the extra stuff for categorized bboard
	}
	
	db_release_unused_handles 

    }
}

set page_content "

$first_part_of_page

<form method=POST action=\"/bboard/q-and-a-post-new\">
<select name=topic_id>
$new_question
</select>
<input type=submit value=\"Post\">
</form>

$rest_of_page

</ul>

<table cellpadding=5>
<tr>
<td> <h3> Forum </h3> </td> <td> <h3> Item </h3> </td> </tr>
$new_posts
</table>

$cat_posts

[bboard_footer]
"

doc_return  200 text/html $page_content
