# /www/survsimp/admin/question-required-toggle.tcl
ad_page_contract {

    Toggle required field for a question.

    @param required_p    flag indicating original status of this question
    @param survey_id     survey this question belongs to
    @param question_id   question we're dealing with

    @author  jsc@arsdigita.com
    @date    February 9, 2000
    @cvs-id  question-required-toggle.tcl,v 1.5.2.5 2000/07/23 16:53:34 seb Exp

} {

    required_p:notnull
    survey_id:integer
    question_id:integer

}
   
db_dml survsimp_question_required_toggle "update survsimp_questions set required_p = logical_negation(required_p)
where survey_id = :survey_id
and question_id = :question_id"

db_release_unused_handles
ad_returnredirect "one?[export_url_vars survey_id]"
