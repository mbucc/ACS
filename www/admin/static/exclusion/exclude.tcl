ad_page_contract {
    @cvs-id exclude.tcl,v 3.0.12.7 2000/09/22 01:36:10 kevin Exp
    @author philg@mit.edu 
    @creation-date November 6, 1999

    /admin/static/exclusion/exclude.tcl
    
    run the exclusion patterns and generate a report for the user
    of what got excluded 
    we could do this all in one huge Oracle statement 
    but we'd rather do it one pattern at a time and report
    the number of rows updated
    
    we don't update any rows where the indexing decision was made
    by a human
} {
}

set page_content "[ad_admin_header "Running Exclusion Patterns"]

<h2>Running Exclusion Patterns</h2>

[ad_admin_context_bar [list "../index.tcl" "Static Content"] "Running Exclusion Pattern"]

<hr>

<ul>

"



set patterns_list [db_list_of_lists static_exclusion_select_page_index_data "select exclusion_pattern_id, match_field, like_or_regexp, pattern, pattern_comment, creation_date, u.user_id, u.first_names || ' ' || u.last_name as users_full_name
from static_page_index_exclusion spie, users u
where spie.creation_user = u.user_id
order by upper(pattern)"]

foreach sublist $patterns_list {
    set exclusion_pattern_id [lindex $sublist 0]
    set match_field [lindex $sublist 1]
    set like_or_regexp [lindex $sublist 2]
    set pattern [lindex $sublist 3]
    set pattern_comment [lindex $sublist 4]
    set creation_date [lindex $sublist 5]
    set user_id [lindex $sublist 6]
    set users_full_name [lindex $sublist 7]
    set sql "update static_pages 
set index_p = 'f'
where lower($match_field) LIKE lower('[DoubleApos $pattern]')
and index_p <> 'f'
and index_decision_made_by = 'robot'"
    append page_content "<li>Going to execute \n\n<blockquote><pre>$sql</pre></blockquote>\n\n ... "
    db_dml unused $sql
    set n_rows_touched [db_resultrows]
    append page_content "$n_rows_touched rows updated.\n"
}

append page_content "

</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_content