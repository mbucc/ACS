# /www/survsimp/admin/question-add-3.tcl
ad_page_contract {
    Inserts a new question into the database.

    @param survey_id               integer denoting which survey we're adding question to
    @param question_id             id of new question
    @param after                   optional integer determining position of this question
    @param question_text           text of question
    @param abstract_data_type      string describing datatype we expect as answer
    @param presentation_type       string describing widget for providing answer
    @param presentation_alignment  string determining placement of answer widget relative to question text
    @param valid_responses         string containing possible choices, one per line
    @param textbox_size            width of textbox answer widget
    @param textarea_cols           number of columns for textarea answer widget
    @param textarea_rows           number of rows for textarea answer widget
    @param required_p              flag telling us whether an answer to this question is mandatory
    @param active_p                flag telling us whether this question will show up at all
    @param category_id             optional integer determining category of thsi question within survey

    @author Jin Choi (jsc@arsdigita.com) February 9, 2000
    @cvs-id question-add-3.tcl,v 1.8.2.6 2001/01/11 23:57:10 khy Exp
} {
    survey_id:integer,notnull
    question_id:integer,notnull,verify
    after:integer,optional
    question_text:html
    abstract_data_type
    presentation_type
    presentation_alignment
    {valid_responses ""}
    {textbox_size ""} 
    {textarea_cols:naturalnum ""} 
    {textarea_rows:naturalnum ""}
    {required_p t}
    {active_p t}
    {category_id:integer ""}
}

set user_id [ad_get_user_id]
survsimp_survey_admin_check $user_id $survey_id

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

db_transaction {
    if { [exists_and_not_null after] } {
	# We're inserting between existing questions; move everybody down.
	set sort_key [expr $after + 1]
	db_dml renumber_sort_keys "update survsimp_questions
set sort_key = sort_key + 1
where survey_id = :survey_id
and sort_key > :after"
    } else {
	set sort_key 1
    }

    db_dml insert_survsimp_question "insert into survsimp_questions (question_id, survey_id, sort_key, question_text, abstract_data_type, presentation_type, presentation_options, presentation_alignment, creation_user, creation_date,active_p, required_p)
 values (:question_id, :survey_id, :sort_key, :question_text, :abstract_data_type, :presentation_type, :presentation_options, :presentation_alignment, :user_id, sysdate, :active_p, :required_p )"
    

    if {[info exists category_id] && ![empty_string_p $category_id]} {
	db_dml categorize_question "insert into site_wide_category_map (map_id, category_id,
on_which_table, on_what_id, mapping_date, one_line_item_desc) 
values (site_wide_cat_map_id_seq.nextval, :category_id, 'survsimp_questions',
:question_id, sysdate, 'Survey')"
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
		db_dml insert_survsimp_question_choice "insert into survsimp_question_choices (choice_id, question_id, label, sort_order)
 values (survsimp_choice_id_sequence.nextval, :question_id, :trimmed_response, :count)"
		incr count
	    }
	}
    }
} on_error {

    set already_inserted_p [db_string already_inserted_p {
select
  decode(count(*),0,0,1)
from
  survsimp_questions
where question_id = :question_id } ]

    if { !$already_inserted_p } {
      db_release_unused_handles
      ad_return_error "Database Error" "<pre>$errmsg</pre>"
      return
    }
}

db_release_unused_handles
ad_returnredirect "one?survey_id=$survey_id"
