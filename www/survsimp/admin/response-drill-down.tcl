#
# /survsimp/admin/response-drill-down.tcl
#
# by philg@mit.edu and jsc@arsdigita.com, February 16, 2000
#
# Display the list of users who gave a particular answer to a
# particular question.

ad_page_variables {question_id choice_id}

set db [ns_db gethandle]

# get the prompt text for the question and the ID for survey of 
# which it is part

set selection [ns_db 0or1row $db "select survey_id, question_text
from survsimp_questions
where question_id = $question_id"]

if [empty_string_p $selection] {
    ad_return_error "Survey Question Not Found" "Could not find a survey question #$question_id"
    return
}

set_variables_after_query

set selection [ns_db 0or1row $db "select label as response_text
from survsimp_question_choices
where choice_id = $choice_id"]

if [empty_string_p $selection] {
    ad_return_error "Response Not Found" "Could not find the response #$choice_id"
    return
}

set_variables_after_query

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id

set survey_name [database_to_tcl_string $db "select name from survsimp_surveys where survey_id = $survey_id"]


set results ""

# Get information of users who responded in particular manner to
# choice question.
set selection [ns_db select $db "select first_names || ' ' || last_name as responder_name, u.user_id, submission_date
from survsimp_responses sr, users u, survsimp_question_responses qr
where qr.response_id = sr.response_id
and sr.user_id = u.user_id
and qr.question_id = $question_id
and qr.choice_id = $choice_id"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append results "<li><a href=\"one-respondent.tcl?[export_url_vars user_id survey_id]\">$responder_name</a>\n"
}

ns_db releasehandle $db

ns_return 200 text/html "[ad_header "People who answered \"$response_text\""]

<h2>Responder List</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] \
     [list "one.tcl?survey_id=$survey_id" "Administer Survey"] \
     [list "responses.tcl?survey_id=$survey_id" "Responses"] \
     "One Response"]

<hr>

$survey_name responders who answered \"$response_text\"
when asked \"$question_text\":

<ul>
$results
</ul>

[ad_footer]
"

