# $Id: admin-q-and-a.tcl,v 3.0 2000/02/06 03:33:11 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic_id required

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}
 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}

# the administrator can always post a new question

set ask_a_question "<a href=\"q-and-a-post-new.tcl?[export_url_vars topic topic_id]\">Post a New Question</a> |"

if { $policy_statement != "" } {
    set about_link "| <a href=\"policy.tcl?[export_url_vars topic topic_id]\">About</a>"
} else {
    set about_link ""
}

if { [bboard_pls_blade_installed_p] } {
    set top_menubar "\[ $ask_a_question
<a href=\"admin-q-and-a-search-form.tcl?[export_url_vars topic topic_id]\">Search</a> |
<a href=\"admin-q-and-a-unanswered.tcl?[export_url_vars topic topic_id]\">Unanswered Questions</a> |
<a href=\"admin-q-and-a-new-answers.tcl?[export_url_vars topic topic_id]\">New Answers</a> 
$about_link
\]"
} else {
    set top_menubar "\[ $ask_a_question
<a href=\"admin-q-and-a-unanswered.tcl?[export_url_vars topic topic_id]\">Unanswered Questions</a> |
<a href=\"q-and-a-new-answers.tcl?[export_url_vars topic topic_id]\">New Answers</a>
$about_link
 \]"
}

set sql "select msg_id, one_line, sort_key, email,first_names || ' ' || last_name as name, interest_level
from bboard, users
where users.user_id = bboard.user_id 
and topic_id = $topic_id
and refers_to is null
and posting_time > (sysdate - $q_and_a_new_days)
order by sort_key $q_and_a_sort_order"

set selection [ns_db select $db $sql]

ReturnHeaders

ns_write "<html>
<head>
<title>Administer $topic by Question</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Administer $topic</h2>

by question (one of the options from <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">the admin home page for this topic</a>)

<hr>

$top_menubar

<h3>New Questions</h3>


<ul>

"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id\">$one_line</a>
<br>
from  (<a href=\"mailto:$email\">$name</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	ns_write " -- interest level $interest_level"
    }

}

ns_write "

</ul>

<h3>Other Groups of Questions</h3>

<ul>
<li><a href=\"admin-q-and-a-all.tcl?[export_url_vars topic topic_id]\">All the Questions</a>
<li><a href=\"admin-q-and-a-category-list.tcl?[export_url_vars topic topic_id]\">Pick a Category</a>
<li><a href=\"admin-q-and-a-new-messages.tcl?[export_url_vars topic topic_id]\">New messages</a> (organized chronologically)

</ul> 

"
ns_write "

[bboard_footer]
"
