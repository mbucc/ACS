# /www/bboard/unified/q-and-a-post-new.tcl
ad_page_contract {
    Display new messages in an individual's forums

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id q-and-a-post-new.tcl,v 1.1.4.4 2000/09/22 01:37:00 kevin Exp
} {}

# -----------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

set page_content "[bboard_header "Ask a new question"]

<h2>Ask a new Question</h2>

[ad_context_bar_ws_or_index [list "/bboard/index" [bboard_system_name]] \
	"Ask a new question"]

<hr>

<h3> Select the Forum where your question will be posted </h3>
<ul>
"

# **** Ideally, this should be called once, at login
# **** This call ensure that the user has access to any new forums and that the 
# **** user's access to any forums that he/she no longer has permission to access
# **** is not compromized by this script
# **** Remove this once ACS is upgraded (e.g., ACS 3.3)
update_user_unified_topics $user_id

db_foreach user_topics "
SELECT bboard_topics.topic AS topic,
       bboard_unified.topic_id AS topic_id,
       bboard_topics.read_access AS read_access
FROM bboard_topics, bboard_unified
WHERE bboard_unified.default_topic_p = 't'
  AND bboard_topics.topic_id = bboard_unified.topic_id
  AND bboard_unified.user_id = :user_id" {

    if { [validate_bboard_access $topic_id $read_access $user_id] } {
	append topics "<li> <a href=\"/bboard/q-and-a-post-new?[export_url_vars topic_id topic]\">$topic</a>"
    }
} if_no_rows {
    append page_content "<li> No forums available for you to ask questions in..."
} 

append page_content "
$topics

</ul>

[bboard_footer]
"

doc_return  200 text/html $page_content