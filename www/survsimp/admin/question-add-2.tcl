# /www/survsimp/admin/question-add-2.tcl
ad_page_contract {

    Based on the presentation type selected in previous form,
    gives the user various options on how to lay out the question.

    @param survey_id          integer determining survey we're dealing with
    @param after              optional integer determining placement of question
    @param question_text      text comprising this question
    @param presentation_type  string denoting widget used to provide answer
    @param required_p         flag indicating whether this question is mandatory
    @param active_p           flag indicating whether this question is active
    @param category_id        optional integer describing category of this question (within survey)

    @author Jin Choi (jsc@arsdigita.com)
    @date   February 9, 2000
    @cvs-id question-add-2.tcl,v 1.8.2.8 2001/01/11 23:56:50 khy Exp
} {

    survey_id:integer
    question_text:html,notnull
    presentation_type
    {after:integer ""}
    {required_p t}
    {active_p t}
    {category_id:integer ""}

}

set user_id [ad_get_user_id]
survsimp_survey_admin_check $user_id $survey_id

set question_id [db_string next_question_id "select survsimp_question_id_sequence.nextval from dual"]

db_1row survsimp_survey_properties "select name, description
from survsimp_surveys
where survey_id = :survey_id"

# Display presentation options for sizing text input fields and textareas.
set presentation_options ""

switch -- $presentation_type {
    "textbox" { 
	set presentation_options "<select name=textbox_size>
<option value=small>Small</option>
<option value=medium>Medium</option>
<option value=large>Large</option>
</select>"
    }
    "textarea" {
	set presentation_options "Rows: <input name=textarea_rows size=3>  Columns: <input name=textarea_cols size=3>"
    }
}

set presentation_options_html ""
if { ![empty_string_p $presentation_options] } {
    set presentation_options_html "Presentation Options: $presentation_options\n"
}

# Let user enter valid responses for selections, radio buttons, and check boxes.

set response_fields ""

switch -- $presentation_type {
    "radio" -
    "select" {
	set response_fields "Select one of the following:<p>

<table border=0 width=80% align=center>
<tr valign=top<td valign=middle align=center>
<td>
<input type=radio name=abstract_data_type value=\"boolean\"> True or False
<td valign=middle>
<b>OR</b>
<td>
 <input type=radio name=abstract_data_type value=\"choice\" checked> Multiple choice (enter one per line):
<blockquote>
<textarea name=valid_responses rows=10 cols=50></textarea>
</blockquote>

</table>
"
	set response_type_html ""
    }

    "checkbox" {
	set response_fields "Valid Responses (enter one per line):
<blockquote>
<textarea name=valid_responses rows=10 cols=80></textarea>
</blockquote>
"
	set response_type_html "<input type=hidden name=abstract_data_type value=\"choice\">"
    }
    "textbox" -
    "textarea" {
	# Fields where users enter free text responses require an abstract type.
	set response_type_html "<p>
Type of Response:
<select name=\"abstract_data_type\">
 <option value=\"shorttext\">Short Text (< 4000 characters)</option>
 <option value=\"text\">Text</option>
 <option value=\"boolean\">Boolean</option>
 <option value=\"number\">Number</option>
 <option value=\"integer\">Integer</option>
</select>
"
    } 
    "date" {
	
	set response_type_html "<input type=hidden name=abstract_data_type value=date>"
    }
    "upload_file" {
	set response_type_html "<input type=hidden name=abstract_data_type value=blob>"
    }

}



doc_return  200 text/html "[ad_header "Add A Question (cont.)"]
<h2>$name</h2>

[ad_context_bar_ws_or_index [list "" "Simple Survey Admin"] [list "one?[export_url_vars survey_id]" "Administer Survey"] "Add A Question"]

<hr>

<form action=\"question-add-3\" method=post>
[export_form_vars survey_id question_text presentation_type after required_p active_p category_id ]
[export_form_vars -sign question_id]

Question:
<blockquote>
$question_text
</blockquote>

$presentation_options_html

$response_type_html

$response_fields

<p>

Response Location: <input type=radio name=presentation_alignment value=\"beside\"> Beside the question<br>
<input type=radio name=presentation_alignment value=\"below\" checked> Below the question

<p>

<center>
<input type=submit value=\"Submit\">
</center>

</form>

[ad_footer]
"
