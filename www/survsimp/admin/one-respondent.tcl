#
# /survsimp/admin/one-respondent.tcl
#
# by jsc@arsdigita.com, February 11, 2000
#
# Display the filled-out survey for a single user.
# 

ad_page_variables {user_id survey_id}

set db [ns_db gethandle]

survsimp_survey_admin_check $db [ad_get_user_id] $survey_id


set selection [ns_db 0or1row $db "select name as survey_name, description
from survsimp_surveys
where survey_id = $survey_id"]

if [empty_string_p $selection] {
    ad_return_error "Not Found" "Could not find survey #$survey_id"
    return
}

set_variables_after_query 

# survey_name and description are now set 

set selection [ns_db 0or1row $db "select first_names, last_name from users where user_id = $user_id"]

if [empty_string_p $selection] {
    ad_return_error "Not Found" "Could not find user #$user_id"
    return
}

set_variables_after_query

set whole_page "[ad_header "Response from $first_names $last_name"]

<h2>Response from $first_names $last_name</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] \
     [list "one.tcl?survey_id=$survey_id" "Administer Survey"] \
     [list "respondents.tcl?survey_id=$survey_id" "Respondents"] \
     "One Respondent"]

<hr>

Here is what <a href=\"/shared/community-member.tcl?[export_url_vars user_id]\">$first_names $last_name</a> had to say in response to $survey_name:


<p>


"

# now we have to query Oracle to find out what the questions are and
# how to present them

set response_id_date_list [database_to_tcl_list_list $db "select response_id, submission_date 
from survsimp_responses
where user_id = $user_id
and survey_id = $survey_id
order by submission_date desc"]

if { ![empty_string_p $response_id_date_list] } {

    foreach response_id_date $response_id_date_list {
	append whole_page "<h3>Response on [lindex $response_id_date 1]</h3> 
[survsimp_answer_summary_display $db [lindex $response_id_date 0] 1 ]
<hr width=50%>"
    }
}


ns_db releasehandle $db

ns_return 200 text/html "$whole_page  

[ad_footer]"
