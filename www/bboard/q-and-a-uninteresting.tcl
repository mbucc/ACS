# /www/bboard/q-and-a-uninteresting.tcl

ad_page_contract {
    returns a listing of the threads that haven't been answered,
    sorted by descending date
    q-and-a-unanswered
    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1995
    @cvs-id q-and-a-uninteresting.tcl,v 3.1.6.4 2000/09/22 01:36:53 kevin Exp
} {
    topic:trim
    topic_id:integer
    q_and_a_sort_order
    q_and_a_categorized_p
}

# we're just looking at the uninteresting postings now

if {[bboard_get_topic_info] == -1} {
    return
}

set page_content "[bboard_header "Uninteresting $topic Threads"]

<h2>Uninteresting Threads</h2>

in the <a href=\"q-and-a?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>

"

if { $q_and_a_categorized_p == "t" } {

    set last_category "there ain't no stinkin' category with this name"
    set first_category_flag 1

    # we present "interest_level == NULL" on the top page
    db_foreach messege "
    select msg_id, 
           one_line, 
           sort_key, 
           email, 
           users.first_names || ' ' || users.last_name as name, 
           category,
           decode(category,'','t','f') as uncategorized_p 
    from   bboard,
           users 
    where  bboard.user_id = users.user_id
    and    topic_id = :topic_id
    and    refers_to is null
    and interest_level < [bboard_interest_level_threshold]
    order by uncategorized_p, category, sort_key $q_and_a_sort_order" {
	
	if { $category != $last_category } {
	    set last_category $category
	    if { $first_category_flag != 1 } {
		# we have to close out a <ul>
		append page_content "\n</ul>\n"
	    } else {
		set first_category_flag 0
	    }
	    if { $category == "" } {
		set pretty_category "Uncategorized"
	    } else {
		set pretty_category $category
	    }
	    append page_content "<h3>$pretty_category</h3>

<ul>
"
       }

       set display_string "$one_line"
       if { $subject_line_suffix == "name" } {
	   append display_string "  ($name)"
       } elseif { $subject_line_suffix == "email" } {
	   append display_string "  ($email)"
       }

       append page_content "<li><a href=\"[bboard_msg_url $presentation_type $msg_id $topic]\">$display_string</a>\n"
   }
} else {
    # not categorized

    append page_content "<ul>\n"

    db_foreach noncategorized "
    select msg_id, 
           one_line, 
           sort_key, 
           email,
           users.first_names || ' ' || users.last_name as name
    from   bboard, 
           users 
    where  bboard.user_id = users.user_id
    and    topic_id = :topic_id
    and    refers_to is null
    and    interest_level < [bboard_interest_level_threshold]
    order by sort_key $q_and_a_sort_order" {

	set display_string "$one_line"
	if { $subject_line_suffix == "name" && $name != "" } {
	    append display_string "  ($name)"
	} elseif { $subject_line_suffix == "email" && $email != "" } {
	    append display_string "  ($email)"
	}
    
	append page_content "<li><a href=\"[bboard_msg_url $presentation_type $msg_id $topic]\">$display_string</a>\n"
    }
}

# let's assume there was at least one section

append page_content "

</ul>

[bboard_footer]
"



doc_return  200 text/html $page_content