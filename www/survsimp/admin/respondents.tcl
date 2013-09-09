# /www/survsimp/admin/respondents.tcl
ad_page_contract {

    List respondents to this survey.

    @param    survey_id  which survey we're displaying respondents to

    @author   jsc@arsdigita.com
    @date     February 11, 2000
    @cvs-id   respondents.tcl,v 1.6.2.5 2000/09/22 01:39:21 kevin Exp
} {

    survey_id:integer

}

set user_id [ad_get_user_id]
survsimp_survey_admin_check $user_id $survey_id

set respondents ""

db_foreach survsimp_survey_respondents "select first_names || ' ' || last_name as name, u.user_id, email
from users u, survsimp_responses r
where u.user_id = r.user_id
and survey_id = :survey_id
group by u.user_id, email, first_names, last_name
order by last_name" {

    append respondents "<li><a href=\"one-respondent?[export_url_vars user_id  survey_id]\">$name ($email)</a>\n"
}

set survey_name [db_string survsimp_name_from_id "select name as survey_name
from survsimp_surveys
where survey_id = :survey_id" ]



doc_return  200 text/html "[ad_header "Respondents to Survey"]
<h2>$survey_name</h2>

[ad_context_bar_ws_or_index [list "" "Simple Survey Admin"] \
     [list "one?survey_id=$survey_id" "Administer Survey"] \
     "Respondents"]

<hr>

<ul>
$respondents
</ul>

[ad_footer]
"

