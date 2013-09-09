# /www/survsimp/admin/one-respondent.tcl
ad_page_contract {

    Display the filled-out survey for a single user.

    @param  user_id    user whose response we're viewing
    @param  survey_id  survey we're viewing
    @author jsc@arsdigita.com
    @date   February 11, 2000
    @cvs-id one-respondent.tcl,v 1.5.2.5 2000/09/22 01:39:20 kevin Exp
} {

    user_id:integer
    survey_id:integer

} 


survsimp_survey_admin_check [ad_get_user_id] $survey_id

set survey_exists_p [db_0or1row survsimp_survey_properties "select name as survey_name, description
from survsimp_surveys
where survey_id = :survey_id" ]

if { !$survey_exists_p } {
    ad_return_error "Not Found" "Could not find survey #$survey_id"
    return
}

# survey_name and description are now set 

set user_exists_p [db_0or1row user_name_from_id "select first_names, last_name from users where user_id = :user_id" ]

if { !$user_exists_p } {
    ad_return_error "Not Found" "Could not find user #$user_id"
    return
}


set whole_page "[ad_header "Response from $first_names $last_name"]

<h2>Response from $first_names $last_name</h2>

[ad_context_bar_ws_or_index [list "" "Simple Survey Admin"] \
     [list "one?survey_id=$survey_id" "Administer Survey"] \
     [list "respondents?survey_id=$survey_id" "Respondents"] \
     "One Respondent"]

<hr>

Here is what <a href=\"/shared/community-member?[export_url_vars user_id]\">$first_names $last_name</a> had to say in response to $survey_name:

<p>

"

# now we have to query Oracle to find out what the questions are and
# how to present them

set response_id_date_list [db_list_of_lists survsimp_survey_response_dates_for_users "select response_id, submission_date 
from survsimp_responses
where user_id = :user_id
and survey_id = :survey_id
order by submission_date desc" ]

if { ![empty_string_p $response_id_date_list] } {

    foreach response_id_date $response_id_date_list {
	append whole_page "<h3>Response on [lindex $response_id_date 1]</h3> 
[survsimp_answer_summary_display [lindex $response_id_date 0] 1 ]
<hr width=50%>"
    }
}



doc_return  200 text/html "$whole_page  

[ad_footer]"
