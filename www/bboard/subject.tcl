ad_page_contract {
    Displays either the feature thread or the designated topic

    @param topic_id - topic id
    @param topic    - topic
    @param start_msg_id - begin with this message to display
    @param feature_msg_id - feature message id
    @cvs-id   subject.tcl,v 3.1.6.6 2000/09/22 01:36:55 kevin Exp
} {
    topic_id:integer
    topic
    {start_msg_id ""}
    feature_msg_id:optional
}

if  {[bboard_get_topic_info] == -1} {
    return
}


if {![empty_string_p $start_msg_id]} {
    set sql "select msg_id
    , one_line
    , sort_key
    , email
    , first_names || ' ' || last_name as name 
    from bboard 
    , users
    where users.user_id = bboard.user_id
    and topic_id = :topic_id
    and msg_id >= :start_msg_id
    order by sort_key"
} else {
    set sql "select msg_id
    , one_line
    , sort_key
    , email
    , first_names || ' ' || last_name as name
    from bboard
    , users
    where users.user_id = bboard.user_id 
    and topic_id = :topic_id
    order by sort_key"
}


set page_content "
[bboard_header "Subject Window for $topic"]

<pre>"

db_foreach select_items $sql {

    set n_spaces [expr 3 * [bboard_compute_msg_level $sort_key]]
    if { $n_spaces == 0 } {
	set pad ""
    } else {
	set pad [format "%*s" $n_spaces " "]
    }

    if {[info exists feature_msg_id] && $feature_msg_id == $msg_id } {
	set display_string "<b>$one_line</b>"
    } else {
	set display_string "$one_line"
    }

    if { $subject_line_suffix == "name" } {
	append display_string "  ($name)"
    } elseif { $subject_line_suffix == "email" } {
	append display_string "  ($email)"
    }
    append page_content "$pad<a target=main href=\"fetch-msg?msg_id=$msg_id\">$display_string</a>\n"

} if_no_rows {
    append page_content "there have been no messages posted to this forum"
}

db_release_unused_handles


append page_content "</pre>
[bboard_footer]
"

doc_return  200 text/html $page_content








