# /www/survsimp/admin/question-swap.tcl
ad_page_contract {

  Swaps two sort keys for a survey, sort_key and sort_key - 1.

  @param  survey_id  survey we're acting upon
  @param  sort_key   integer determining position of question which is
                     about to be replaced with previous one

  @cvs-id question-swap.tcl,v 1.4.2.3 2000/07/21 04:04:18 ron Exp

} {

  survey_id:integer,notnull
  sort_key:integer,notnull
  
}


set user_id [ad_get_user_id]
survsimp_survey_admin_check $user_id $survey_id

set next_sort_key [expr $sort_key - 1]

db_transaction {
    db_dml swap_sort_keys "update survsimp_questions
set sort_key = decode(sort_key, :sort_key, :next_sort_key, :next_sort_key, :sort_key)
where survey_id = :survey_id
and sort_key in (:sort_key, :next_sort_key)"

    ad_returnredirect "one?[export_url_vars survey_id]"

} on_error {

    ad_return_error "Database error" "A database error occured while trying
to swap your questions. Here's the error:
<pre>
$errmsg
</pre>
"
}
