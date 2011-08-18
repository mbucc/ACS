#
# /survsimp/one.tcl
#
# by philg@mit.edu, February 9, 2000
#
# display the user's previous responses
# 

ad_page_variables {survey_id {return_url ""} {group_id ""}}

# survey_id, maybe return_url, maybe group_id

set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id $db]

set selection [ns_db 0or1row $db "select name, description
from survsimp_surveys
where survey_id = $survey_id"]

if [empty_string_p $selection] {
    ad_return_error "Not Found" "Could not find survey #$survey_id"
    return
}

set_variables_after_query 

# name and description are now set 

set whole_page "[ad_header $name]

<h2>$name</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Surveys"] [list "one.tcl?[export_url_vars survey_id]" "One survey"] "Responses"]

<hr>

$description 


<p>


"



set response_id_date_list [database_to_tcl_list_list $db "select response_id, submission_date 
from survsimp_responses
where user_id = $user_id
and survey_id = $survey_id
order by submission_date desc"]

if { ![empty_string_p $response_id_date_list] } {
    

    foreach response_id_date $response_id_date_list {
	append whole_page "<h3> Your response on [lindex $response_id_date 1]</h3> 
[survsimp_answer_summary_display $db [lindex $response_id_date 0] 1]
<hr width=50%>"
    }
}

append whole_page "
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $whole_page 
