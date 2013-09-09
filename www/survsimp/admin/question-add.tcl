# /www/survsimp/admin/question-add.tcl
ad_page_contract {
    Present form to begin adding a question to a survey.
    Lets user enter the question and select a presentation type.

    @param survey_id    integer designating survey we're adding question to
    @param after        optinal integer denoting position of question within survey

    @author  jsc@arsdigita.com
    @date    February 9, 2000
    @cvs-id question-add.tcl,v 1.6.2.9 2000/09/22 01:39:21 kevin Exp
} {
    survey_id:integer
    {after:integer ""}
}


set user_id [ad_get_user_id]
survsimp_survey_admin_check $user_id $survey_id

db_1row simpsurv_survey_properties "select name, description
from survsimp_surveys
where survey_id = :survey_id" 

set category_option_list [db_html_select_value_options categories_select_options "select 
site_wide_category_map.category_id, category from
site_wide_category_map, categories
where categories.category_id = site_wide_category_map.category_id
and on_what_id = :survey_id
and on_which_table = 'survsimp_surveys'"]

if ![empty_string_p $category_option_list] {
    set category_text "Category:
<select name=\"category_id\">
$category_option_list
</select>"
} else {
    set category_text ""
}


doc_return  200 text/html "[ad_header "Add A Question"]
<h2>$name</h2>

[ad_context_bar_ws_or_index [list "" "Simple Survey Admin"] [list "one?[export_url_vars survey_id]" "Administer Survey"] "Add A Question"]

<hr>

<form action=\"question-add-2\" method=post>
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
<option value=\"upload_file\">File Attachment</option>
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
