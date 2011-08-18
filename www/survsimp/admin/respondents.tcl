#
# /survsimp/admin/respondents.tcl
#
# by jsc@arsdigita.com, February 11, 2000
#
# List respondents to this survey.
# 
#$Id: respondents.tcl,v 1.3 2000/03/13 03:36:06 teadams Exp $
#


ad_page_variables {survey_id}

set db [ns_db gethandle]

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id


set selection [ns_db select $db "select first_names || ' ' || last_name as name, u.user_id, email
from users u, survsimp_responses r
where u.user_id = r.user_id
and survey_id = $survey_id
group by u.user_id, email, first_names, last_name
order by last_name"]


set respondents ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append respondents "<li><a href=\"one-respondent.tcl?[export_url_vars user_id  survey_id]\">$name ($email)</a>\n"
}

set survey_name [database_to_tcl_string $db "select name as survey_name
from survsimp_surveys
where survey_id = $survey_id"]



ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Respondents to Survey"]
<h2>$survey_name</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] \
     [list "one.tcl?survey_id=$survey_id" "Administer Survey"] \
     "Respondents"]

<hr>

<ul>
$respondents
</ul>

[ad_footer]
"


