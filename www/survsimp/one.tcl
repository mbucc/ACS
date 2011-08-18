#
# /survsimp/one.tcl
#
# by philg@mit.edu, February 9, 2000
#
# display a questionnaire for one survey
# 
#$Id: one.tcl,v 1.5 2000/03/13 04:43:12 teadams Exp $
#


ad_page_variables {survey_id {return_url ""} {group_id ""}}

# survey_id, maybe return_url, maybe group_id

set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id $db]

set selection [ns_db 0or1row $db "select name, description
from survsimp_surveys
where survey_id = $survey_id"]

if [empty_string_p $selection] {
    ad_return_error "Not Found" "Could not find survey #$survey_id"
    return
}

set_variables_after_query 

# name and description are now set 

set whole_page "[ad_header $name]

<h2>$name</h2>

 [ad_context_bar_ws_or_index [list "index.tcl" "Surveys"] "One Survey"]

<hr>

$description 


<p>

<blockquote>

"

# now we have to query Oracle to find out what the questions are and
# how to present them; let's store up the IDs in a Tcl list so that
# we don't need two database handles

set question_ids [database_to_tcl_list $db "select question_id
from survsimp_questions
where survey_id = $survey_id
and active_p = 't'
order by sort_key"]

append whole_page "

<form method=POST action=\"process-response.tcl\">
[export_form_vars survey_id return_url group_id]

<ol>
"

foreach question_id $question_ids {
    # give them a new page
    append whole_page "<li>[survsimp_question_display $db $question_id]\n"
}


append whole_page "</ol>\n
<center>
<input type=submit value=\"Submit Response\">
</center>
</form>
</blockquote>

"


set num_responses [database_to_tcl_string $db "select count(response_id)
from survsimp_responses
where user_id = $user_id
and survey_id = $survey_id
order by submission_date desc"]

if {$num_responses > 0 } {
    append whole_page "<a href=one-respondent.tcl?[export_url_vars survey_id]>Your previous responses</a>"
}

append whole_page "
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $whole_page 
