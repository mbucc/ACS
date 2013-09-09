# /www/survsimp/admin/question-active-toggle.tcl
ad_page_contract {

    Toggles if a response to required for a given question.

    @param  survey_id    survey we're operating with
    @param  question_id  denotes which question in survey we're updating

    @cvs-id question-active-toggle.tcl,v 1.5.2.4 2000/07/21 04:04:11 ron Exp
} {

    survey_id:integer
    question_id:integer

}


db_dml survsimp_question_required_toggle "update survsimp_questions set active_p = logical_negation(active_p)
where survey_id = :survey_id
and question_id = :question_id"

db_release_unused_handles
ad_returnredirect "one?[export_url_vars survey_id]"

