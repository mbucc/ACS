#
# /survsimp/process-response.tcl
#
# by jsc@arsdigita.com, February 9, 2000
#
# Insert user response into database.
#
# $Id: process-response.tcl,v 1.3.2.9 2000/04/28 15:11:30 carsten Exp $
#

set_the_usual_form_variables

# response_to_question_$question_id, survey_id, maybe return_url, maybe group_id

set user_id [ad_verify_and_get_user_id]

if {[info exists group_id] && ![empty_string_p $group_id]} {
    set scope "group"

} else {
    set scope "public"
}

set db [ns_db gethandle]


if {[ad_scope_authorization_status $db $scope all group_member user $group_id ] != "authorized" && ![im_user_is_employee_p $db $user_id]} {
    # you are allowed to submit a report if you are in the group
    # or if you are an employee
    ad_return_error "Not authorized" "You are not authorized for this function."
    return
}


set question_info_list [database_to_tcl_list_list $db "select question_id, question_text, abstract_data_type, presentation_type, required_p
from survsimp_questions
where survey_id = $survey_id
and active_p = 't'
order by sort_key"]

## Validate input.

set questions_with_missing_responses [list]
set exception_count 0
set exception_text ""


foreach question $question_info_list { 
    set question_id [lindex $question 0]
    set question_text [lindex $question 1]
    set abstract_data_type [lindex $question 2]
    set required_p [lindex $question 4]

    if { $abstract_data_type == "date" } {
	if [catch  { ns_dbformvalue [ns_conn form] response_to_question_$question_id date response_to_question_$question_id} errmsg] {
	    incr exception_count
	    append exception_text "<li>Please make sure your dates are valid."
	}
    }

    if { [exists_and_not_null response_to_question_$question_id] } {
	set response_value [string trim [set response_to_question_$question_id]]
    } elseif {$required_p == "t"} {
	lappend questions_with_missing_responses $question_text
	continue
    } else {
	set response_to_question_$question_id ""
	set response_value ""
    }

    if { $abstract_data_type == "number" } {
	if { ![regexp {^(-?[0-9]+\.)?[0-9]+$} $response_value] } {
	    incr exception_count
	    append exception_text "<li>The response to \"$question_text\" must be a number. Your answer was \"$response_value\".\n"
	    continue
	}
    } elseif { $abstract_data_type == "integer" } {
	if { ![regexp {^[0-9]+$} $response_value] } {
	    incr exception_count
	    append exception_text "<li>The response to \"$question_text\" must be an integer. Your answer was \"$response_value\".\n"
	    continue
	}
    }
}

set missing_expression_count [llength $questions_with_missing_responses]

if { $missing_expression_count > 0 } {
    incr exception_count $missing_expression_count
    append exception_text "<li>You didn't respond to all required sections. You skipped:
<ul>
<li>[join $questions_with_missing_responses "\n<li>"]
</ul>
"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}


# Do the inserts.

set response_id [database_to_tcl_string $db "select survsimp_response_id_sequence.nextval from dual"]

with_transaction $db {

    ns_db dml $db "insert into survsimp_responses (response_id, survey_id, user_id, ip_address, group_id, scope)
 values ($response_id, $survey_id, $user_id, '[ns_conn peeraddr]', [ns_dbquotevalue $group_id],'$scope')"

    foreach question $question_info_list { 
	set question_id [lindex $question 0]
	set question_text [lindex $question 1]
	set abstract_data_type [lindex $question 2]
	set presentation_type [lindex $question 3]

	set response_value [string trim [set response_to_question_$question_id]]

	switch -- $abstract_data_type {
	    "choice" {
		if { $presentation_type == "checkbox" } {
		    # Deal with multiple responses.
		    set checked_responses [util_GetCheckboxValues [ns_conn form] response_to_question_$question_id [list]]
		    foreach response_value $checked_responses {
			if { [empty_string_p $response_value] } {
			    set response_value "null"
			}

			ns_db dml $db "insert into survsimp_question_responses (response_id, question_id, choice_id)
 values ($response_id, $question_id, $response_value)"
		    }
		} else {
		    if { [empty_string_p $response_value] } {
			set response_value "null"
		    }

		    ns_db dml $db "insert into survsimp_question_responses (response_id, question_id, choice_id)
 values ($response_id, $question_id, $response_value)"
		}
	    }
	    "shorttext" {
		ns_db dml $db "insert into survsimp_question_responses (response_id, question_id, varchar_answer)
 values ($response_id, $question_id, '[DoubleApos $response_value]')"
	    }
	    "boolean" {
		if { [empty_string_p $response_value] } {
		    set response_value "null"
		} else {
		    set response_value "'$response_value'"
		}

		ns_db dml $db "insert into survsimp_question_responses (response_id, question_id, boolean_answer)
 values ($response_id, $question_id, $response_value)"
	    }
	    "number" -
	    "integer" {
                if { [empty_string_p $response_value] } {
                    set response_value "null"
                } 

		ns_db dml $db "insert into survsimp_question_responses (response_id, question_id, number_answer)
 values ($response_id, $question_id, $response_value)"
	    }
	    "text" {
                if { [empty_string_p $response_value] } {
                    set response_value " "
                } 

		ns_ora clob_dml $db "insert into survsimp_question_responses (response_id, question_id, clob_answer)
 values ($response_id, $question_id, empty_clob())
 returning clob_answer into :1" $response_value
	    }
	    "date" {
                if { [empty_string_p $response_value] } {
                    set response_value "null"
                } else {
                    set response_value "'$response_value'"
                }

		ns_db dml $db "insert into survsimp_question_responses (response_id, question_id, date_answer)
 values ($response_id, $question_id, $response_value)"
	    }
	}
    }
} {
    ad_return_error "Database Error" "There was an error while trying to process your response:
<pre>
$errmsg
</pre>
"
    return
}



set survey_name [database_to_tcl_string $db "select name from survsimp_surveys
where survey_id = $survey_id"]

ns_db releasehandle $db

if {[info exists return_url] && ![empty_string_p $return_url]} {
    ad_returnredirect $return_url
    return
}

ns_return 200 text/html "[ad_header "Response Submitted"]
<h2>$survey_name</h2>

 [ad_context_bar_ws_or_index [list "index.tcl" "Surveys"] "One Survey"]

<hr>

<blockquote>
Response submitted. Thank you.
</blockquote>

[ad_footer]
"
