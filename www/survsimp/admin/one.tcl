#
# /survsimp/admin/one.tcl
#
# by jsc@arsdigita.com, February 9, 2000
#
# administer a single survey (add/delete questions)
# 
#$Id: one.tcl,v 1.4.2.2 2000/03/16 03:04:29 nuno Exp $
#

ad_page_variables {survey_id}

set dbs [ns_db gethandle main 2]
set db [lindex $dbs 0]
set sub_db [lindex $dbs 1]

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id

# Get the survey information.
set selection [ns_db 1row $db "select name as survey_name, short_name, description as survey_description, first_names || ' ' || last_name as creator_name, creation_user, creation_date, decode(enabled_p, 't', 'Enabled', 'f', 'Disabled') as survey_status
from survsimp_surveys, users
where survey_id = $survey_id
and users.user_id = survsimp_surveys.creation_user"]

set_variables_after_query


# Questions summary.
set selection [ns_db select $db "select question_id, sort_key, active_p, required_p, nvl(category, 'uncategorized') as category
from survsimp_questions, categories,
  (select * from  site_wide_category_map 
   where site_wide_category_map.on_which_table = 'survsimp_questions') map
where survey_id = $survey_id  
and map.category_id = categories.category_id (+)
and map.on_what_id (+) = survsimp_questions.question_id
order by sort_key"]

set questions_summary "<form><ol>\n"
set count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query


    set question_options [list "<a href=\"question-delete.tcl?question_id=$question_id\">delete</a>" \
			      "<a href=\"question-add.tcl?[export_url_vars survey_id]&after=$sort_key\">insert after</a>"]
    if { $count > 0 } {
	lappend question_options "<a href=\"question-swap.tcl?[export_url_vars survey_id sort_key]\">swap with prev</a>"
    }
    if {$active_p == "t"} {
	lappend question_options "Active: <a href=\"question-active-toggle?[export_url_vars survey_id question_id active_p]\">inactivate</a>"
	if {$required_p == "t"} {
	    lappend question_options "Response Required: <a href=\"question-required-toggle?[export_url_vars survey_id question_id required_p]\">don't require</a>"
	} else {
	    lappend question_options "Response Not Required: <a href=\"question-required-toggle?[export_url_vars survey_id question_id required_p]\">require</a>"
	}
    } else {
	lappend question_options "Inactive: <a href=\"question-active-toggle?[export_url_vars survey_id question_id active_p]\">activate</a>"
    }

    append questions_summary "<li>[survsimp_question_display $sub_db $question_id] 
<br>
<font size=-1>
Category: $category <p>
\[ [join $question_options " | "] \]
</font>

<p>"
    incr count
}

if { $count == 0 } {
    append questions_summary "<p><a href=\"question-add.tcl?survey_id=$survey_id\">Add a question</a>\n"
}

append questions_summary "</ol></form>\n"

set supported_categories [database_to_tcl_list $db "select category
from site_wide_category_map, categories
where site_wide_category_map.category_id = categories.category_id
and on_which_table = 'survsimp_surveys'
and on_what_id = $survey_id"] 

ns_db releasehandle $db

ReturnHeaders
ns_write "[ad_header "Administer Survey"]
<h2>$survey_name</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] "Administer Survey"]

<hr>


<ul>
<li>Created by: <a href=\"/shared/community-member.tcl?user_id=$creation_user\">$creator_name</a>
<li>Short name: $short_name
<li>Created: [util_AnsiDatetoPrettyDate $creation_date]
<li>Status: $survey_status <font size=-1>(can be changed from site-wide admin pages)</font>
<li>Description: $survey_description <font size=-1>\[ <a href=\"description-edit.tcl?[export_url_vars survey_id]\">edit</a> \]</font>

<li>Question categories: [join $supported_categories "," ] 
<form action=survey-category-add.tcl method=post>
[export_form_vars survey_id]
<input type=type name=category Maxlength=20>
<input type=submit name=submit value=\"Add Category\">
</form>
<p>
<li>View responses:  <a href=\"respondents.tcl?survey_id=$survey_id\">by user</a>
|
<a href=\"responses.tcl?survey_id=$survey_id\">summary</a>
</ul>
<p>



$questions_summary

[ad_footer]
"
