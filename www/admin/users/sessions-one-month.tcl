ad_page_contract {
    @cvs-id sessions-one-month.tcl,v 3.2.2.3.2.3 2000/09/22 01:36:22 kevin Exp
} {
    pretty_month:notnull
    pretty_year:notnull
}


append whole_page "[ad_admin_header "Sessions in $pretty_month, $pretty_year"]

<h2>$pretty_month $pretty_year</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] [list "session-history.tcl" "Session History"] "One Month"]

<hr>

<blockquote>

<table>
<tr>
  <th>Date
  <th>Sessions
  <th>Repeats
</tr>

"


set sql "select 
  entry_date, 
  to_char(entry_date,'fmDD') as day_number,
  session_count, 
  repeat_count
from session_statistics
where rtrim(to_char(entry_date,'Month')) = :pretty_month
and to_char(entry_date,'YYYY') = :pretty_year
order by entry_date"

db_foreach admin_users_sessions_one_month  $sql {
    append whole_page "
<tr>
  <td>$pretty_month $day_number
  <td align=right>[util_commify_number $session_count]
  <td align=right>[util_commify_number $repeat_count]
</tr>
"
}

append whole_page "

</table>
</blockquote>

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
