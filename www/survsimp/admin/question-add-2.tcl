#
# /survsimp/admin/question-add-2.tcl
#
# by jsc@arsdigita.com, February 9, 2000
#
# Based on the presentation type selected in previous form,
# gives the user various options on how to lay out the question.
# 

ad_page_variables {survey_id {after ""} question_text presentation_type {required_p t} {active_p t} {category_id ""}}
set db [ns_db gethandle]

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id


set selection [ns_db 1row $db "select name, description
from survsimp_surveys
where survey_id = $survey_id"]

set_variables_after_query


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
}



ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Add A Question (cont.)"]
<h2>$name</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] [list "one.tcl?[export_url_vars survey_id]" "Administer Survey"] "Add A Question"]

<hr>

<form action=\"question-add-3.tcl\" method=GET>
[export_entire_form]

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
