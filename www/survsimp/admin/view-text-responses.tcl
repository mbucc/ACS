#
# /survsimp/admin/view-text-responses.tcl
#
# by jsc@arsdigita.com, February 11, 2000
#
# View all the typed-in text responses for one question.
# 

ad_page_variables {question_id}

set db [ns_db gethandle]

set user_id [ad_get_user_id]
set selection [ns_db 1row $db "select question_text, survey_id
from survsimp_questions
where question_id = $question_id"]
set_variables_after_query

survsimp_survey_admin_check $db $user_id $survey_id


set abstract_data_type [database_to_tcl_string $db "select abstract_data_type
from survsimp_questions q
where question_id = $question_id"]

if { $abstract_data_type == "text" } {
    set column_name "clob_answer"
} elseif { $abstract_data_type == "shorttext" } {
    set column_name "varchar_answer"
} elseif { $abstract_data_type == "date" } {
    set column_name "date_answer"
}

set selection [ns_db select $db "select $column_name as response, u.user_id, first_names || ' ' || last_name as respondent_name, submission_date, ip_address
from survsimp_responses r, survsimp_question_responses qr, users u
where qr.response_id = r.response_id
and u.user_id = r.user_id
and qr.question_id = $question_id
order by r.submission_date"]

set results ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append results "<pre>$response</pre>
<p>
-- <a href=\"/shared/community-member.tcl?user_id=$user_id\">$respondent_name</a> on $submission_date from $ip_address

<br>
"
}



ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Responses to Question"]
<h2>$question_text</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] \
     [list "one.tcl?survey_id=$survey_id" "Administer Survey"] \
     [list "responses.tcl?survey_id=$survey_id" "Responses to Survey"] \
     "Responses to Question"]

<hr>

<blockquote>
$results
</blockquote>

[ad_footer]
"
