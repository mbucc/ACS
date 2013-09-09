# /www/survsimp/admin/view-text-responses.tcl
ad_page_contract {

  View all the typed-in text responses for one question.

  @param  question_id  which question we want to list answers to
 
  @author jsc@arsdigita.com
  @date   February 11, 2000
  @cvs-id view-text-responses.tcl,v 1.5.2.4 2000/09/22 01:39:22 kevin Exp

} {

  question_id:integer,notnull

}

set user_id [ad_get_user_id]

db_1row one_question "
  select question_text, survey_id
  from survsimp_questions
  where question_id = :question_id"

survsimp_survey_admin_check $user_id $survey_id

set abstract_data_type [db_string abstract_data_type "select abstract_data_type
from survsimp_questions q
where question_id = :question_id"]

if { $abstract_data_type == "text" } {
    set column_name "clob_answer"
} elseif { $abstract_data_type == "shorttext" } {
    set column_name "varchar_answer"
} elseif { $abstract_data_type == "date" } {
    set column_name "date_answer"
}

set results ""

db_foreach all_responses_to_question "
select
  $column_name as response,
  u.user_id,
  first_names || ' ' || last_name as respondent_name,
  submission_date,
  ip_address
from
  survsimp_responses r,
  survsimp_question_responses qr,
  users u
where
  qr.response_id = r.response_id
  and u.user_id = r.user_id
  and qr.question_id = :question_id
order by r.submission_date" {

    append results "<pre>$response</pre>
<p>
-- <a href=\"/shared/community-member?user_id=$user_id\">$respondent_name</a> on $submission_date from $ip_address

<br>
"
}



doc_return  200 text/html "[ad_header "Responses to Question"]
<h2>$question_text</h2>

[ad_context_bar_ws_or_index [list "" "Simple Survey Admin"] \
     [list "one?survey_id=$survey_id" "Administer Survey"] \
     [list "responses?survey_id=$survey_id" "Responses to Survey"] \
     "Responses to Question"]

<hr>

<blockquote>
$results
</blockquote>

[ad_footer]
"
