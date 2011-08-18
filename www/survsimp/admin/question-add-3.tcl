#
# /survsimp/admin/question-add-3.tcl
#
# by jsc@arsdigita.com, February 9, 2000
#
# Create the question and bounce the user back to the survey administration page.
# 
#$Id: question-add-3.tcl,v 1.3.2.3 2000/04/28 15:11:33 carsten Exp $
#

ad_page_variables {survey_id {after ""} question_text abstract_data_type presentation_type presentation_alignment {valid_responses ""} {textbox_size ""} {textarea_cols ""} {textarea_rows ""} {active_p "t"} {required_p "t"} {category_id ""}}

set exception_count 0
set exception_text ""

if { [empty_string_p $question_text] } {
    incr exception_count
    append exception_text "<li>You did not enter a question."
}

if { $abstract_data_type == "choice" && [empty_string_p $valid_responses] } {
    incr exception_count
    append exception_text "<li>You did not enter a list of valid responses/choices."
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id]

survsimp_survey_admin_check $db $user_id $survey_id

# Generate presentation_options.
set presentation_options ""
if { $presentation_type == "textarea" } {
    if { [exists_and_not_null textarea_rows] } {
	append presentation_options " rows=$textarea_rows"
    }
    if { [exists_and_not_null textarea_cols] } {
	append presentation_options " cols=$textarea_cols"
    }
} elseif { $presentation_type == "textbox" } {
    if { [exists_and_not_null textbox_size] } {
	# Will be "small", "medium", or "large".
	set presentation_options $textbox_size
    }
}



set new_question_id [database_to_tcl_string $db "select survsimp_question_id_sequence.nextval from dual"]

with_transaction $db {
    if { [exists_and_not_null after] } {
	# We're inserting between existing questions; move everybody down.
	set sort_key [expr $after + 1]
	ns_db dml $db "update survsimp_questions
set sort_key = sort_key + 1
where survey_id = $survey_id
and sort_key > $after"
    } else {
	set sort_key 1
    }

    ns_db dml $db "insert into survsimp_questions (question_id, survey_id, sort_key, question_text, abstract_data_type, presentation_type, presentation_options, presentation_alignment, creation_user, creation_date,active_p, required_p)
 values ($new_question_id, $survey_id, $sort_key, '$QQquestion_text', '$abstract_data_type', '$presentation_type', '[DoubleApos $presentation_options]', '$presentation_alignment', $user_id, sysdate, '$required_p', '$active_p')"
    

    if {[info exists category_id] && ![empty_string_p $category_id]} {
	ns_db dml $db "insert into site_wide_category_map (map_id, category_id,
on_which_table, on_what_id, mapping_date, one_line_item_desc) 
values (site_wide_cat_map_id_seq.nextval, $category_id, 'survsimp_questions',
$new_question_id, sysdate, 'Survey')"
    }
    # For questions where the user is selecting a canned response, insert
    # the canned responses into survsimp_question_choices by parsing the valid_responses
    # field.
    if { $presentation_type == "checkbox" || $presentation_type == "radio" || $presentation_type == "select" } {
	if { $abstract_data_type == "choice" } {
	    set responses [split $valid_responses "\n"]
	    set count 0
	    foreach response $responses {
		set trimmed_response [string trim $response]
		if { [empty_string_p $trimmed_response] } {
		    # skip empty lines
		    continue
		}
		ns_db dml $db "insert into survsimp_question_choices (choice_id, question_id, label, sort_order)
 values (survsimp_choice_id_sequence.nextval, $new_question_id, '[DoubleApos $trimmed_response]', $count)"
		incr count
	    }
	}
    }
} {
    ad_return_error "Database Error" "<pre>$errmsg</pre>"
    return
}

ad_returnredirect "one.tcl?survey_id=$survey_id"