# /www/survsimp/admin/question-delete.tcl
ad_page_contract {

  Delete a question from a survey, along with all responses.

  @param  question_id     question we're deleting
  @author jsc@arsdigita.com
  @date   March 13, 2000
  @cvs-id question-delete-2.tcl,v 1.6.2.5 2000/09/12 01:02:46 nuno Exp
} {

    question_id:integer

}

set user_id [ad_get_user_id]

set survey_id [db_string survsimp_survey_id_from_question_id "select survey_id from survsimp_questions where question_id = :question_id" ]
survsimp_survey_admin_check $user_id $survey_id

db_transaction {
    db_dml survsimp_question_responses_delete "delete from survsimp_question_responses where question_id = :question_id" 

    db_dml survsimp_question_choices_delete "delete from survsimp_question_choices where question_id = :question_id" 

    db_dml survsimp_questions_delete "delete from survsimp_questions where question_id = :question_id" 

    # reset question sort keys
    set new_sort_key 1
    db_foreach survsimp_all_question_ids_from_survey_id "select question_id as question_id_for_update
      from survsimp_questions 
      where survey_id = :survey_id
      order by sort_key asc" {
          db_dml survsimp_question_reset_sort_key "update survsimp_questions 
            set sort_key = :new_sort_key 
            where question_id = :question_id_for_update"
          incr new_sort_key
      }
} on_error {
    ad_return_error "Database Error" "There was an error while trying to delete the question:
        <pre>
        $errmsg
        </pre>
        <p> Please go back to the <a href=\"one?survey_id=$survey_id\">survey</a>.
        "
        return
}

db_release_unused_handles
ad_returnredirect "one?survey_id=$survey_id"

