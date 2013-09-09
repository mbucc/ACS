# /www/survsimp/admin/question-delete.tcl
ad_page_contract {

    Delete a question from a survey
    (or ask for confirmation if there are responses).

    @param  question_id  question we're about to delete

    @author jsc@arsdigita.com
    @date   March 13, 2000
    @cvs-id question-delete.tcl,v 1.5.2.6 2000/09/22 01:39:21 kevin Exp
} {

    question_id:integer

}

set user_id [ad_get_user_id]

set survey_id [db_string survsimp_id_from_qeustion_id "select survey_id from survsimp_questions where question_id = :question_id" ]

survsimp_survey_admin_check $user_id $survey_id

set n_responses [db_string survsimp_number_responses "select count(*)
from survsimp_question_responses
where question_id = :question_id" ]

if { $n_responses == 0 } {
    db_transaction {

	db_dml survsimp_delete_question_choices "delete from survsimp_question_choices where question_id = :question_id" 

	db_dml survsimp_delete_questions "delete from survsimp_questions where question_id = :question_id" 

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
	<p> Please go back using your browser.
	"
	return
    }

    db_release_unused_handles
    ad_returnredirect "one?survey_id=$survey_id"
    return
} else {
    
    doc_return  200 text/html "[ad_header "Confirm Question Deletion"]
<h2>Really Delete?</h2>

[ad_context_bar_ws_or_index [list "" "Simple Survey Admin"] [list "one?[export_url_vars survey_id]" "Administer Survey"] "Delete Question"]

<hr>

Deleting this question will also delete all $n_responses responses. Really delete?
<p>
<a href=\"question-delete-2?[export_url_vars question_id]\">Yes</a> / 
<a href=\"one?[export_url_vars survey_id]\">No</a>

[ad_footer]
"
}
