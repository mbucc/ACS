#
# /survsimp/admin/question-required-toggle.tcl
#
# by jsc@arsdigita.com, February 9, 2000
#
# toggle required field for a question.
# 
# $Id: question-required-toggle.tcl,v 1.1.2.2 2000/04/28 15:11:34 carsten Exp $
#



ad_page_variables {required_p survey_id question_id}

set db [ns_db gethandle]

ns_db dml $db "update survsimp_questions set required_p = logical_negation(required_p)
where question_id = $question_id"

ad_returnredirect "one.tcl?[export_url_vars survey_id]"
