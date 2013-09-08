# /www/survsimp/admin/question-modify-text-2.tcl
ad_page_contract {

    Submission page for allowing the user to modify the text of a question.

    @param question_id   which question we'll be changing text of
    @param survey_id     survey providing this question
    @param question_text new text of question

    @author cmceniry@arsdigita.com, Jun 16, 2000
    @cvs-id question-modify-text-2.tcl,v 1.1.2.7 2000/07/21 04:04:15 ron Exp
} {

    question_id:integer
    survey_id:integer
    question_text:html,notnull

}


set user_id [ad_get_user_id]
survsimp_survey_admin_check $user_id $survey_id

db_dml survey_question_text_update "update survsimp_questions set question_text=:question_text where question_id=:question_id" 

db_release_unused_handles
ad_returnredirect "one.tcl?survey_id=$survey_id"

