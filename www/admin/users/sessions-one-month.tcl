# $Id: sessions-one-month.tcl,v 3.1 2000/03/09 00:01:37 scott Exp $
set_the_usual_form_variables

# pretty_month, pretty_year


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

set db [ns_db gethandle]
set selection [ns_db select $db "select 
  entry_date, 
  to_char(entry_date,'fmDD') as day_number,
  session_count, 
  repeat_count
from session_statistics
where rtrim(to_char(entry_date,'Month')) = '$QQpretty_month'
and to_char(entry_date,'YYYY') = '$QQpretty_year'
order by entry_date"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
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
ns_db releasehandle $db
ns_return 200 text/html $whole_page
