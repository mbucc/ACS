# /www/survsimp/process-response.tcl
ad_page_contract {

    Insert user response into database.
    This page receives an input for each question named
    response_to_question.$question_id 

    @param   survey_id             survey user is responding to
    @param   return_url            optional redirect address
    @param   group_id              
    @param   response_to_question  since form variables are now named as response_to_question.$question_id, this is actually array holding user responses to all survey questions.
    @param   response_id           previously generated id, to detect double-clicking

    @author  jsc@arsdigita.com
    @date    February 9, 2000
    @cvs-id  process-response.tcl,v 1.12.2.14 2001/01/12 00:01:43 khy Exp
} {

  survey_id:integer,notnull
  return_url:optional
  {group_id:integer ""}
  response_to_question:array,optional,multiple,html
  response_id:integer,notnull,verify
}


set user_id [ad_verify_and_get_user_id]

if {[info exists group_id] && ![empty_string_p $group_id]} {
    set scope "group"
} else {
    set scope "public"
}

if {[ad_scope_authorization_status $scope all group_member user $group_id ] != "authorized" && ![im_user_is_employee_p $user_id]} {
    # you are allowed to submit a report if you are in the group
    # or if you are an employee
    ad_return_error "Not authorized" "You are not authorized for this function."
    return
}

# double-click protection
set double_click_p [db_string double_click_check "select count(*) from survsimp_responses where response_id = :response_id"]

if {$double_click_p} {
    # to avoid possible confusion, don't make the user aware of a double-click (ie, show exact same result as a valid click)...

    if {[info exists return_url] && ![empty_string_p $return_url]} {
	ad_returnredirect "$return_url"
	return
    } else {
	set survey_name [db_string survsimp_name_from_id "select name from survsimp_surveys where survey_id = :survey_id" ]

	doc_return  200 text/html "[ad_header "Response Submitted"]
	  <h2>$survey_name</h2>
	
	  [ad_context_bar_ws_or_index [list "index.tcl" "Surveys"] "One Survey"]
	
	  <hr>
	
	  <blockquote>
	  Response submitted. Thank you.
	  </blockquote>
	
	  [ad_footer]"
    }
}


set peeraddr [ns_conn peeraddr]

set question_info_list [db_list_of_lists survsimp_question_info_list "select question_id, question_text, abstract_data_type, presentation_type, required_p
from survsimp_questions
where survey_id = :survey_id
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

    #  Need to clean-up after mess with :array,multiple flags
    #  in ad_page_contract.  Because :multiple flag will surround empty
    #  strings and all multiword values with one level of curly braces {}
    #  we need to get rid of them for almost any abstract_data_type
    #  except 'choice', where this is intended behaviour.  Why bother
    #  with :multiple flag at all?  Because otherwise we would lose all
    #  but first value for 'choice' abstract_data_type - see ad_page_contract
    #  doc and code for more info.
    #
    if { [exists_and_not_null response_to_question($question_id)] } {
	if {$abstract_data_type != "choice"} {
	    set response_to_question($question_id) [join $response_to_question($question_id)]
	}
    }
    
    if { $abstract_data_type=="choice" && $required_p=="t" \
	 && [llength $response_to_question($question_id)]==1 \
	 && [string length [lindex $response_to_question($question_id) 0]]==0 } {
	    lappend questions_with_missing_responses $question_text
    }
      

    if { $abstract_data_type == "date" } {
	if [catch  { set response_to_question($question_id) [validate_ad_dateentrywidget "" response_to_question.$question_id [ns_getform]]} errmsg] {
	    incr exception_count
	    append exception_text "<li>$errmsg: Please make sure your dates are valid."
	}
    }
    
    if { [exists_and_not_null response_to_question($question_id)] } {
	set response_value [string trim $response_to_question($question_id)]
    } elseif {$required_p == "t"} {
	lappend questions_with_missing_responses $question_text
	continue
    } else {
	set response_to_question($question_id) ""
	set response_value ""
    }

    if {![empty_string_p $response_value]} {
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
    if { $abstract_data_type == "blob" } {
        set tmp_filename $response_to_question($question_id.tmpfile)
        set n_bytes [file size $tmp_filename]
        if { $n_bytes == 0 && $required_p == "t" } {
            incr exception_count
            append exception_text "Your file is zero-length. Either you attempted to upload a zero length file, a file which does not exist, or something went wrong during the transfer."
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

db_transaction {
    
    if { [empty_string_p $group_id] } {
      set group_id [db_null]
    }

    db_dml survsimp_response_insert "insert into survsimp_responses (response_id, survey_id, user_id, ip_address, group_id, scope)
 values (:response_id, :survey_id, :user_id, :peeraddr, :group_id ,:scope)" 

    foreach question $question_info_list { 
	set question_id [lindex $question 0]
	set question_text [lindex $question 1]
	set abstract_data_type [lindex $question 2]
	set presentation_type [lindex $question 3]

	set response_value [string trim $response_to_question($question_id)]

	switch -- $abstract_data_type {
	    "choice" {
		if { $presentation_type == "checkbox" } {
		    # Deal with multiple responses. 
		    set checked_responses $response_to_question($question_id)
		    foreach response_value $checked_responses {
			if { [empty_string_p $response_value] } {
			    set response_value [db_null]
			}

			db_dml survsimp_question_response_checkbox_insert "insert into survsimp_question_responses (response_id, question_id, choice_id)
 values (:response_id, :question_id, :response_value)"
		    }
		}  else {
		    set selected_response [string trim [join $response_to_question($question_id)]]
		    if { [empty_string_p $selected_response] } {
			set selected_response [db_null]
		    }

		    db_dml survsimp_question_response_choice_insert "insert into survsimp_question_responses (response_id, question_id, choice_id)
 values (:response_id, :question_id, :selected_response)"
		}
	    }
	    "shorttext" {
		db_dml survsimp_question_choice_shorttext_insert "insert into survsimp_question_responses (response_id, question_id, varchar_answer)
 values (:response_id, :question_id, :response_value)"
	    }
	    "boolean" {
		if { [empty_string_p $response_value] } {
		    set response_value [db_null]
		}

		db_dml survsimp_question_response_boolean_insert "insert into survsimp_question_responses (response_id, question_id, boolean_answer)
 values (:response_id, :question_id, :response_value)"
	    }
	    "number" {}
	    "integer" {
                if { [empty_string_p $response_value] } {
                    set response_value [db_null]
                } 

		db_dml survsimp_question_response_integer_insert "insert into survsimp_question_responses (response_id, question_id, number_answer)
 values (:response_id, :question_id, :response_value)"
	    }
	    "text" {
                if { [empty_string_p $response_value] } {
                    set response_value [db_null]
                }

		db_dml survsimp_question_response_text_insert "
insert into survsimp_question_responses
(response_id, question_id, clob_answer)
values (:response_id, :question_id, empty_clob())
 returning clob_answer into :1" -clobs [list $response_value]
	    }
	    "date" {
                if { [empty_string_p $response_value] } {
                    set response_value [db_null]
                }

		db_dml survsimp_question_response_date_insert "insert into survsimp_question_responses (response_id, question_id, date_answer)
 values (:response_id, :question_id, :response_value)"
	    }   
            "blob" {
                if { ![empty_string_p $response_value] } {
                    # this stuff only makes sense to do if we know the file exists
		    set tmp_filename $response_to_question($question_id.tmpfile)
                    set file_extension [string tolower [file extension $response_value]]
                    # remove the first . from the file extension
                    regsub {\.} $file_extension "" file_extension
                    set guessed_file_type [ns_guesstype $response_value]

                    set n_bytes [file size $tmp_filename]
                    # strip off the C:\directories... crud and just get the file name
                    if ![regexp {([^/\\]+)$} $response_value match client_filename] {
                        # couldn't find a match
                        set client_filename $response_value
                    }
                    if { $n_bytes == 0 } {
                        error "This should have been checked earlier."
                    } else {

                        db_dml survsimp_question_response_blob_insert "insert into survsimp_question_responses (response_id, question_id, attachment_answer, attachment_file_name, attachment_file_type, attachment_file_extension)
 values (:response_id, :question_id, empty_blob(), :response_value, :guessed_file_type, :file_extension) returning attachment_answer into :1" -blob_files [list $tmp_filename] 
                       
		    }
                }
            }
	}
    }
} on_error {
    ad_return_error "Database Error" "There was an error while trying to process your response:
<pre>
$errmsg
</pre>
"
    return
}

set survey_name [db_string survsimp_name_from_id "select name from survsimp_surveys
where survey_id = :survey_id" ]


if {[info exists return_url] && ![empty_string_p $return_url]} {
    ad_returnredirect "$return_url"
    return
} else {
    doc_return  200 text/html "[ad_header "Response Submitted"]
    <h2>$survey_name</h2>

    [ad_context_bar_ws_or_index [list "index.tcl" "Surveys"] "One Survey"]

    <hr>
    
    <blockquote>
    Response submitted. Thank you.
    </blockquote>
    
    [ad_footer]
    "
}
