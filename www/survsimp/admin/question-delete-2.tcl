#
# /survsimp/admin/question-delete-2.tcl
#
# by jsc@arsdigita.com, March 13, 2000
#
# delete a question from a survey, along with all responses
# 
# $Id: question-delete-2.tcl,v 1.1.2.3 2000/04/28 15:11:33 carsten Exp $

ad_page_variables {question_id}

set db [ns_db gethandle]

set survey_id [database_to_tcl_string $db "select survey_id from survsimp_questions where question_id = $question_id"]

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id

with_transaction $db {
    ns_db dml $db "delete from survsimp_question_responses where question_id = $question_id"
    ns_db dml $db "delete from survsimp_question_choices where question_id = $question_id"
    ns_db dml $db "delete from survsimp_questions where question_id = $question_id"
} { ad_return_error "Database Error" "There was an error while trying to delete the question:
        <pre>
        $errmsg
        </pre>
        <p> Please go back to the <a href=\"one.tcl?survey_id=$survey_id\">survey</a>.
        "
        return
}


ad_returnredirect "one.tcl?survey_id=$survey_id"



