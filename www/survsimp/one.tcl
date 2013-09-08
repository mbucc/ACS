# /www/survsimp/one.tcl
ad_page_contract {

    Display a questionnaire for one survey.

    @param  survey_id   id of displayed survey
    @param  return_url  optional URL user will be redirected to after completing the survey
    @param  group_id    parameter passed to following page
    @param  template    if supplied, used as a page-building template

    @author philg@mit.edu
    @date   February 9, 2000
    @cvs-id one.tcl,v 1.14.2.8 2001/01/12 00:00:43 khy Exp
} {

    survey_id:integer,notnull
    {return_url ""}
    {group_id:integer ""}
    {template ""}

}


set user_id [ad_verify_and_get_user_id]

if { ![db_0or1row survey_params "select name, description, single_response_p, single_editable_p from survsimp_surveys where survey_id = :survey_id" ] } {
    ad_return_error "Not Found" "Could not find survey #$survey_id"
    return
}

# now we have to query Oracle to find out what the questions are and
# how to present them; let's store up the IDs in a Tcl list so that
# we don't need two database handles

set question_ids [db_list questions_list "select question_id
from survsimp_questions
where survey_id = :survey_id
and active_p = 't'
order by sort_key" ]

# generate response_id, for double-click protection
set response_id [db_string survsimp_sequence_next "select survsimp_response_id_sequence.nextval from dual"]

set form_html "

<form enctype=multipart/form-data method=POST action=\"process-response\">

[export_form_vars survey_id return_url group_id]
[export_form_vars -sign response_id]

<ol>
"

set num_responses [db_string responses_count "select count(response_id)
  from survsimp_responses
  where user_id = :user_id
  and survey_id = :survey_id " ]

if {$single_response_p == "t"} {
    if {$num_responses == "0"} {
	set button_label "Submit response"
	set edit_previous_response_p "f"
    } else {
	set button_label "Modify submited response"
	set edit_previous_response_p "t"
    }
    set previous_responses_link ""
} else {
    set button_label "Submit response"
    set edit_previous_response_p "f"
    if {$num_responses == "0"} {
        set previous_responses_link ""
    } else {
        set previous_responses_link "<a href=one-respondent?[export_url_vars survey_id]>Your previous responses</a>"
    }
}

foreach question_id $question_ids {
    # give them a new page
    append form_html "<li>[survsimp_question_display $question_id $edit_previous_response_p]\n"
}

if {$single_response_p == "t" && $single_editable_p == "f"} {
    set submit_button "This response has been submited and can not be modified. <br> Please go back using your browser."
} else {
    set submit_button "<input type=submit value=\"$button_label\">"
}

append form_html "</ol>\n
<center>
$submit_button
</center>
</form>
"

set page_title $name
set context_bar [ad_context_bar_ws_or_index [list "index.tcl" "Surveys"] "One Survey"]
set page_body "<blockquote>
  $description
  $form_html
  </blockquote>
"

db_release_unused_handles

if {![empty_string_p $template]} {
    ad_return_template $template
} else {
    set whole_page "
    [ad_header $page_title]

    <h2>$page_title</h2>
    
    $context_bar 

    <hr>
    
    $page_body 
    $previous_responses_link
    
    <p>
    
    [ad_footer]
    "
    doc_return  200 text/html $whole_page 
}
