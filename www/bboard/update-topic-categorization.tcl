# $Id: update-topic-categorization.tcl,v 3.0 2000/02/06 03:34:50 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, q_and_a_categorized_p, q_and_a_solicit_category_p
# q_and_a_categorization_user_extensible_p, q_and_a_new_days, 
# bunch of other new ones

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if {[bboard_get_topic_info] == -1} {
    return
}

set update_sql [util_prepare_update $db bboard_topics topic $topic [ns_conn form]]

if [catch {ns_db dml $db $update_sql} errmsg] {
    ns_return 200 text/html "<html>
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

set selection [ns_db 1row $db "select unique * from bboard_topics where topic_id = $topic_id"]
set_variables_after_query

ReturnHeaders

ns_write  "<html>
<head>
<title>Topic Updated</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Topic Updated</h2>

\"$topic\" updated in 
<a href=\"index.tcl\">[bboard_system_name]</a>

<hr>

<ul>
"

if { $q_and_a_categorized_p == "t" } {
    ns_write "<li>When offered to users in Q&A forum format, this topic will be categorized.  I.e., new questions will be presented chronologically on top but older questions will be sorted by category.\n"
} else {
    ns_write "<li>When offered to users in Q&A forum format, this topic will <em>not</em> be categorized.  I.e., all questions will be presented chronologically.\n"
}

ns_write "<li>The definition of a \"new\" question will be \"posted within the last $q_and_a_new_days days.\"\n"

if { $q_and_a_solicit_category_p == "t" } {
    ns_write "<li>When users post a question, this system will ask them to suggest a category for the question.\n"
} else {
    ns_write "<li>When users post a question, this system will <em>not</em> ask them to suggest a category for the question; the administrator (i.e., you) will have to hand-categorize all the questions.\n"
}

if { $q_and_a_categorization_user_extensible_p == "t" } {
    ns_write "<li>Users will be allowed to suggest new categories.\n"
} else {
    ns_write "<li>Users will <em>not</em> be allowed to suggest new categories.\n"
}

ns_write "

</ul>

[bboard_footer]"
