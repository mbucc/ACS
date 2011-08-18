#
# /survsimp/admin/question-add.tcl
#
# by jsc@arsdigita.com, February 9, 2000
#
# Present form to begin adding a question to a survey.
# Lets user enter the question and select a presentation type.
# 

ad_page_variables {survey_id {after ""}}

set db [ns_db gethandle]

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id


set selection [ns_db 1row $db "select name, description
from survsimp_surveys
where survey_id = $survey_id"]

set_variables_after_query

set category_option_list [db_html_select_value_options $db "select 
site_wide_category_map.category_id, category from
site_wide_category_map, categories
where categories.category_id = site_wide_category_map.category_id
and on_what_id = $survey_id
and on_which_table = 'survsimp_surveys'"]

if ![empty_string_p $category_option_list] {
    set category_text "Category:
<select name=\"category_id\">
$category_option_list
</select>"
} else {
    set category_text ""
}


ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Add A Question"]
<h2>$name</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] [list "one.tcl?[export_url_vars survey_id]" "Administer Survey"] "Add A Question"]

<hr>

<form action=\"question-add-2.tcl\" method=GET>
[export_form_vars survey_id after]

Question:
<blockquote>
<textarea name=question_text rows=5 cols=70></textarea>
</blockquote>

<p>

Response Presentation:
<select name=\"presentation_type\">
<option value=\"textbox\">Text Field</option>
<option value=\"textarea\">Text Area</option>
<option value=\"select\">Selection</option>
<option value=\"radio\">Radio Buttons</option>
<option value=\"checkbox\">Checkbox</option>
<option value=\"date\">Date</option>
</select>
<p>
$category_text
<p>
Active? 
<input type=radio value=t name=active_p checked>Yes
<input type=radio value=f name=active_p>No
<br>
Required?
<input type=radio value=t name=required_p checked>Yes
<input type=radio value=f name=required_p>No

<center>
<input type=submit value=\"Continue\">
</center>


</form>

[ad_footer]
"




