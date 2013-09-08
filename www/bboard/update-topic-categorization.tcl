# /www/bboard/update-topic-categorization.tcl
ad_page_contract {
    Updates categorization information for a topic.

    @cvs-id update-topic-categorization.tcl,v 3.1.6.6 2000/09/22 01:36:56 kevin Exp
} {
    topic:notnull
}

# -----------------------------------------------------------------------------

if {[bboard_get_topic_info] == -1} {
    return
}


# Nasty, nasty, nasty

set update_sql_and_bind_vars [util_prepare_update bboard_topics topic $topic [ns_conn form]]
set update_sql [lindex $update_sql_and_bind_vars 0]
set bind_vars [lindex $update_sql_and_bind_vars 1]

if [catch {db_dml topic_categorization_update $update_sql -bind $bind_vars} errmsg] {
    doc_return  200 text/html "<html>
<head>
<title>Topic Not Updated</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Topic Not Updated</h2>

<hr>

The database rejected the update of discussion topic \"$topic\".  Here was
the error message:

<pre>
$errmsg
</pre>

<hr>
<a href=\"mailto:[bboard_system_owner]\"><address>[bboard_system_owner]</address></a>

</body>
</html>"
return 0 

}

# the database insert went OK

db_1row topic_info "
select unique * from bboard_topics where topic_id = :topic_id"

append page_content  "
[bboard_header "Topic Updated"]

<h2>Topic Updated</h2>

\"$topic\" updated in 
<a href=\"index\">[bboard_system_name]</a>

<hr>

<ul>
"

if { $q_and_a_categorized_p == "t" } {
    append page_content "<li>When offered to users in Q&A forum format, this topic will be categorized.  I.e., new questions will be presented chronologically on top but older questions will be sorted by category.\n"
} else {
    append page_content "<li>When offered to users in Q&A forum format, this topic will <em>not</em> be categorized.  I.e., all questions will be presented chronologically.\n"
}

append page_content "<li>The definition of a \"new\" question will be \"posted within the last $q_and_a_new_days days.\"\n"

if { $q_and_a_solicit_category_p == "t" } {
    append page_content "<li>When users post a question, this system will ask them to suggest a category for the question.\n"
} else {
    append page_content "<li>When users post a question, this system will <em>not</em> ask them to suggest a category for the question; the administrator (i.e., you) will have to hand-categorize all the questions.\n"
}

if { $q_and_a_categorization_user_extensible_p == "t" } {
    append page_content "<li>Users will be allowed to suggest new categories.\n"
} else {
    append page_content "<li>Users will <em>not</em> be allowed to suggest new categories.\n"
}

append page_content "

</ul>

[bboard_footer]"

doc_return 200 text/html $page_content