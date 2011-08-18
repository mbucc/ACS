ad_page_variables {survey_id question_id}

set db [ns_db gethandle]

ns_db dml $db "update survsimp_questions set active_p = logical_negation(active_p)
where question_id = $question_id"

ad_returnredirect "one.tcl?[export_url_vars survey_id]"
