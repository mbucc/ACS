#
# /survsimp/admin/responses.tcl
#
# by jsc@arsdigita.com, February 11, 2000
#
# View summary of all responses to one survey.
# 

ad_page_variables {survey_id}

set dbs [ns_db gethandle main 2]

set db [lindex $dbs 0]
set sub_db [lindex $dbs 1]

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id


set results ""

set selection [ns_db select $db "select question_id, question_text, abstract_data_type
from survsimp_questions
where survey_id = $survey_id
order by sort_key"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append results "<li>$question_text
<blockquote>
"
    switch -- $abstract_data_type {
	"date" -
	"text" -
	"shorttext" {
	    append results "<a href=\"view-text-responses.tcl?question_id=$question_id\">View responses</a>\n"
	}
	
	"boolean" {
	    set sub_selection [ns_db select $sub_db "select count(*) as n_responses, decode(boolean_answer, 't', 'True', 'f', 'False') as boolean_answer
from survsimp_question_responses
where question_id = $question_id
group by boolean_answer
order by boolean_answer desc"]
	    while { [ns_db getrow $sub_db $sub_selection] } {
		set_variables_after_subquery
		append results "$boolean_answer: $n_responses<br>\n"
	    }
	}
	"integer" -
	"number" {
	    set sub_selection [ns_db select $sub_db "select count(*) as n_responses, number_answer
from survsimp_question_responses
where question_id = $question_id
group by number_answer
order by number_answer"]
	    while { [ns_db getrow $sub_db $sub_selection] } {
		set_variables_after_subquery
		append results "$number_answer: $n_responses<br>\n"
	    }
	    set sub_selection [ns_db 1row $sub_db "select avg(number_answer) as mean, stddev(number_answer) as standard_deviation
from survsimp_question_responses
where question_id = $question_id"]
	    set_variables_after_subquery
	    append results "<p>Mean: $mean<br>Standard Dev: $standard_deviation<br>\n"
	}
	"choice" {
	    set sub_selection [ns_db select $sub_db "select count(*) as n_responses, label, qc.choice_id
from survsimp_question_responses qr, survsimp_question_choices qc
where qr.choice_id = qc.choice_id
  and qr.question_id = $question_id
group by label, sort_order, qc.choice_id
order by sort_order"]
	    while { [ns_db getrow $sub_db $sub_selection] } {
		set_variables_after_subquery
		append results "$label: <a href=\"response-drill-down.tcl?[export_url_vars question_id choice_id]\">$n_responses</a><br>\n"
	    }
	}
    }
    append results "</blockquote>\n"
}

set survey_name [database_to_tcl_string $db "select name as survey_name
from survsimp_surveys
where survey_id = $survey_id"]

set n_responses [database_to_tcl_string $db "select count(*)
from survsimp_responses
where survey_id = $survey_id"]

if { $n_responses == 1 } {
    set response_sentence "There has been 1 response."
} else {
    set response_sentence "There have been $n_responses responses."
}



ns_db releasehandle $db
ns_db releasehandle $sub_db

ns_return 200 text/html "[ad_header "Responses to Survey"]
<h2>$survey_name</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] \
     [list "one.tcl?survey_id=$survey_id" "Administer Survey"] \
     "Responses"]

<hr>

$response_sentence

<ul>
$results
</ul>

[ad_footer]
"

