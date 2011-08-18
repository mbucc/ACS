# Swaps two sort keys for a survey, sort_key and sort_key - 1.

ad_page_variables {survey_id sort_key}

set db [ns_db gethandle]

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id


set next_sort_key [expr $sort_key - 1]

with_catch errmsg {
    ns_db dml $db "update survsimp_questions
set sort_key = decode(sort_key, $sort_key, $next_sort_key, $next_sort_key, $sort_key)
where survey_id = $survey_id
and sort_key in ($sort_key, $next_sort_key)"

    ad_returnredirect "one.tcl?[export_url_vars survey_id]"
} {
    ad_return_error "Database error" "A database error occured while trying
to swap your questions. Here's the error:
<pre>
$errmsg
</pre>
"
}