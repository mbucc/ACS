# /www/bboard/admin-q-and-a.tcl
ad_page_contract {
    actually shows the questions so that an admin can choose 
    some to view/moderate; Q&A style presentation

    @param topic_id the ID of the bboard topic

    @author philg@mit.edu
    @creation-date 1995
    @cvs-id admin-q-and-a.tcl,v 3.3.2.3 2000/09/22 01:36:46 kevin Exp
} {
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

# the administrator can always post a new question

set ask_a_question "<a href=\"q-and-a-post-new?[export_url_vars topic topic_id]\">Post a New Question</a> |"

if { $policy_statement != "" } {
    set about_link "| <a href=\"policy?[export_url_vars topic topic_id]\">About</a>"
} else {
    set about_link ""
}

if { [bboard_pls_blade_installed_p] } {
    set top_menubar "\[ $ask_a_question
<a href=\"admin-q-and-a-search-form?[export_url_vars topic topic_id]\">Search</a> |
<a href=\"admin-q-and-a-unanswered?[export_url_vars topic topic_id]\">Unanswered Questions</a> |
<a href=\"admin-q-and-a-new-answers?[export_url_vars topic topic_id]\">New Answers</a> 
$about_link
\]"
} else {
    set top_menubar "\[ $ask_a_question
<a href=\"admin-q-and-a-unanswered?[export_url_vars topic topic_id]\">Unanswered Questions</a> |
<a href=\"q-and-a-new-answers?[export_url_vars topic topic_id]\">New Answers</a>
$about_link
 \]"
}

append page_content "<html>
<head>
<title>Administer $topic by Question</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Administer $topic</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] [list "admin-home?[export_url_vars topic topic_id]" "Administer"] "By Question"]

<hr>

$top_menubar

<h3>New Questions</h3>

<ul>

"


db_foreach messages "
select msg_id, 
       one_line, 
       sort_key, 
       email,
       first_names || ' ' || last_name as name, 
       interest_level
from   bboard, 
       users
where  users.user_id = bboard.user_id 
and    topic_id = :topic_id
and    refers_to is null
and    posting_time > (sysdate - :q_and_a_new_days)
order by sort_key $q_and_a_sort_order" {

    append page_content "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg?msg_id=$msg_id\">$one_line</a>
<br>
from  (<a href=\"mailto:$email\">$name</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	append page_content " -- interest level $interest_level"
    }

}

append page_content "

</ul>

<h3>Other Groups of Questions</h3>

<ul>
<li><a href=\"admin-q-and-a-all?[export_url_vars topic topic_id]\">All the Questions</a>
<li><a href=\"admin-q-and-a-category-list?[export_url_vars topic topic_id]\">Pick a Category</a>
<li><a href=\"admin-q-and-a-new-messages?[export_url_vars topic topic_id]\">New messages</a> (organized chronologically)

</ul> 


[bboard_footer]
"

doc_return  200 text/html $page_content


