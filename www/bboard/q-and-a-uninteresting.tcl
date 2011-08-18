# $Id: q-and-a-uninteresting.tcl,v 3.0 2000/02/06 03:34:23 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic required

# we're just looking at the uninteresting postings now

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}


ReturnHeaders

ns_write "[bboard_header "Uninteresting $topic Threads"]

<h2>Uninteresting Threads</h2>

in the <a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>


"

if { $q_and_a_categorized_p == "t" } {
    # we present "interest_level == NULL" on the top page
    set sql "select msg_id, one_line, sort_key, email, users.first_names || ' ' || users.last_name as name, category, decode(category,'','t','f') as uncategorized_p 
from bboard, users 
where bboard.user_id = users.user_id
and topic_id = $topic_id
and refers_to is null
and interest_level < [bboard_interest_level_threshold]
order by uncategorized_p, category, sort_key $q_and_a_sort_order"
    set selection [ns_db select $db $sql]

    set last_category "there ain't no stinkin' category with this name"
    set first_category_flag 1

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if { $category != $last_category } {
	    set last_category $category
	    if { $first_category_flag != 1 } {
		# we have to close out a <ul>
		ns_write "\n</ul>\n"
	    } else {
		set first_category_flag 0
	    }
	    if { $category == "" } {
		set pretty_category "Uncategorized"
	    } else {
		set pretty_category $category
	    }
	    ns_write "<h3>$pretty_category</h3>

<ul>
"
       }
       set display_string "$one_line"
       if { $subject_line_suffix == "name" } {
	   append display_string "  ($name)"
       } elseif { $subject_line_suffix == "email" } {
	   append display_string "  ($email)"
       }
       ns_write "<li><a href=\"[bboard_msg_url $presentation_type $msg_id $topic]\">$display_string</a>\n"
}
} else {
    # not categorized
    set sql "select msg_id, one_line, sort_key, email,  users.first_names || ' ' || users.last_name as name
from bboard, users 
where bboard.user_id = users.user_id
and topic_id = $topic_id
and refers_to is null
and interest_level < [bboard_interest_level_threshold]
order by sort_key $q_and_a_sort_order"
    set selection [ns_db select $db $sql]

ns_write "<ul>\n"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set display_string "$one_line"
    if { $subject_line_suffix == "name" && $name != "" } {
	append display_string "  ($name)"
    } elseif { $subject_line_suffix == "email" && $email != "" } {
	append display_string "  ($email)"
    }
    ns_write "<li><a href=\"[bboard_msg_url $presentation_type $msg_id $topic]\">$display_string</a>\n"

}
}

# let's assume there was at least one section

ns_write "

</ul>


[bboard_footer]
"
