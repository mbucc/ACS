# /www/survsimp/one-respondent.tcl
ad_page_contract {

    Display the user's previous responses.

    @param   survey_id   id of survey for which responses are displayed
    @param   return_url  if provided, generate a 'return' link to that URL
    @param   group_id    if specified, display all the responses for all
                         users of that group

    @author  philg@mit.edu
    @date    February 9, 2000
    @cvs-id  one-respondent.tcl,v 1.8.2.5 2000/09/22 01:39:19 kevin Exp
} {

    survey_id:integer
    {return_url ""}
    {group_id:integer ""}

}

# If group_id is specified, we return all the responses for that group by any user

set user_id [ad_verify_and_get_user_id]

if { ![db_0or1row survsimp_survey_properties "select name, description
from survsimp_surveys
where survey_id = :survey_id"] } {
    ad_return_error "Not Found" "Could not find survey #$survey_id"
    return
}

# name and description are now set 

set page_content "[ad_header $name]
<h2>$name</h2>

[ad_context_bar_ws_or_index [list "" "Surveys"] [list "one?[export_url_vars survey_id]" "One survey"] "Responses"]

<hr>
$description 

<p>

"
if { ![empty_string_p $group_id] } {
    set limit_to_sql "group_id = :group_id"
} else {
    set limit_to_sql "user_id = :user_id"
}

set date_list [list]
set pretty_date_list [list]
set whole_page ""

set response_id_date_list [db_list_of_lists survsimp_response_id_date_list "select response_id, submission_date 
from survsimp_responses
where $limit_to_sql
and survey_id = :survey_id
order by submission_date desc"]

if { ![empty_string_p $response_id_date_list] } {
    foreach response_id_date $response_id_date_list {
        set pretty_current_date [util_AnsiDatetoPrettyDate [lindex $response_id_date 1]]
        set current_date [lindex $response_id_date 1]

        # if the current date is a new date (not in date_list), then add it to the date list
        if { [lsearch -exact $date_list $current_date] == -1 } {
            lappend date_list $current_date
            lappend pretty_date_list "<a href=#$current_date>$pretty_current_date</a>"
            set date_string "<a name=\"$current_date\">Your response on $pretty_current_date</a>"
        } else {
            set date_string "Your response on $pretty_current_date"
        }
        
        append whole_page "
        <table width=100% cellpadding=2 cellspacing=2 border=0>
        <tr bgcolor=#e6e6e6>
          <td>$date_string</td>
        </tr>
        <tr bgcolor=#f4f4f4>
          <td>[survsimp_answer_summary_display [lindex $response_id_date 0] 1]
        </tr>
        </table><br>"
    }
}

append page_content "[join $pretty_date_list " | "] <p> $whole_page [ad_footer]"


doc_return  200 text/html $page_content
