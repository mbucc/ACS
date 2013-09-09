ad_page_contract {
    Returns information on session histories available for browsing.

    @cvs-id session-history.tcl,v 3.3.2.3.2.5 2000/09/22 01:36:22 kevin Exp
} {
}

append whole_page "[ad_admin_header "Session History"]

<h2>Session History</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "Session History"]

<hr>

<blockquote>

<table>
<tr>
  <th>Month<th>Total Sessions<th>Repeat Sessions
</tr>
"
# we have to query for pretty month and year separately because Oracle pads
# month with spaces that we need to trim

set last_year ""
db_foreach admin_users_session_history_list {
    select to_char(entry_date,'YYYYMM') as sort_key, 
          rtrim(to_char(entry_date,'Month')) as pretty_month, to_char(entry_date,'YYYY') as pretty_year, 
          sum(session_count) as total_sessions, sum(repeat_count) as total_repeats
    from session_statistics
    group by to_char(entry_date,'YYYYMM'), to_char(entry_date,'Month'), to_char(entry_date,'YYYY')
    order by 1
} {
    if { $last_year != $pretty_year } {
	if { ![empty_string_p $last_year] } {
	    # insert a line break
	    append whole_page "<tr><td colspan=2>&nbsp;</tr>\n"
	}
	set last_year $pretty_year
    }
    append whole_page "<tr>
<td><a href=\"sessions-one-month?[export_url_vars pretty_month pretty_year]\">$pretty_month $pretty_year</a>
<td align=right>[util_commify_number $total_sessions]</td>
<td align=right>[util_commify_number $total_repeats]</td>
</tr>
"
}

append whole_page "
</table>
</blockquote>

[ad_style_bodynote "Note: we distinguish between a repeat and a new session by seeing
whether the last_visit cookie is set.  The new session figures are
inflated to the extent that users have disabled cookies."]

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
