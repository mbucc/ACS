# /www/survsimp/admin/question-modify-text.tcl
ad_page_contract {

    Allow the user to modify the text of a question.

    @param   survey_id   survey this question belongs to
    @param   question_id question which text we're changing

    @author  cmceniry@arsdigita.com
    @date    Jun 16, 2000
    @cvs-id  question-modify-text.tcl,v 1.1.2.6 2000/09/22 01:39:21 kevin Exp
} {

    question_id:integer
    survey_id:integer

}


set user_id [ad_get_user_id]

survsimp_survey_admin_check $user_id $survey_id

set survey_name [db_string survey_name_from_id "select name from survsimp_surveys where survey_id=:survey_id" ]

set question_text [db_string survsimp_question_text_from_id "select question_text
from survsimp_questions
where question_id = :question_id" ]


doc_return  200 text/html "[ad_header "Modify A Question's Text"]
<h2>$survey_name</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] [list "one.tcl?[export_url_vars survey_id]" "Administer Survey"] "Modify a Question's Text"]

<hr>

<form action=\"question-modify-text-2\" method=GET>
[export_form_vars question_id survey_id]
Question:
<blockquote>
<textarea name=question_text rows=5 cols=70>[ns_quotehtml $question_text]</textarea>
</blockquote>

<p>

<center>
<input type=submit value=\"Continue\">
</center>


</form>

[ad_footer]
"
