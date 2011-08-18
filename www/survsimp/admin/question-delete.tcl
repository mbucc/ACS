#
# /survsimp/admin/question-delete.tcl
#
# by jsc@arsdigita.com, March 13, 2000
#
# delete a question from a survey (or ask for confirmation if there are responses)
# 
# $Id: question-delete.tcl,v 1.1.4.5 2000/04/28 15:11:34 carsten Exp $

ad_page_variables {question_id}

set db [ns_db gethandle]

set survey_id [database_to_tcl_string $db "select survey_id from survsimp_questions where question_id = $question_id"]

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id

set n_responses [database_to_tcl_string $db "select count(*)
from survsimp_question_responses
where question_id = $question_id"]

if { $n_responses == 0 } {
    with_transaction $db {
	ns_db dml $db "delete from survsimp_question_choices where question_id = $question_id"
	ns_db dml $db "delete from survsimp_questions where question_id = $question_id"
    } { ad_return_error "Database Error" "There was an error while trying to delete the question:
	<pre>
	$errmsg
	</pre>
	<p> Please go back using your browser.
	"
	return
    }

    ad_returnredirect "one.tcl?survey_id=$survey_id"
    return
} else {
    ns_return 200 text/html "[ad_header "Confirm Question Deletion"]
<h2>Really Delete?</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] [list "one.tcl?[export_url_vars survey_id]" "Administer Survey"] "Delete Question"]

<hr>

Deleting this question will also delete all $n_responses responses. Really delete?
<p>
<a href=\"question-delete-2.tcl?[export_url_vars question_id]\">Yes</a> / 
<a href=\"one.tcl?[export_url_vars survey_id]\">No</a>

[ad_footer]
"
}