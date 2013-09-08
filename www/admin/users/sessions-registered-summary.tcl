ad_page_contract {
    @cvs-id sessions-registered-summary.tcl,v 3.3.2.4.2.4 2000/09/22 01:36:23 kevin Exp

    sessions-registered-summary.tcl

    by philg@mit.edu sometime in 1999

    displays a table of number of users who haven't logged in 
    for X days
} {
    go_beyond_60_days_p:optional
}


append whole_page "[ad_admin_header "Registered Sessions"]

<h2>Registered Sessions</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "Registered Sessions"]

<hr>

<blockquote>

<table cellpadding=5>
<tr>
  <th>N Days Since Last Visit<th>Total Sessions<th>Repeat Sessions
</tr>

"



# we have to query for pretty month and year separately because Oracle pads
# month with spaces that we need to trim

set sql "select round(sysdate-last_visit) as n_days, count(*) as n_sessions, count(second_to_last_visit) as n_repeats
from users
where last_visit is not null
group by round(sysdate-last_visit)
order by 1"

set table_rows ""

db_foreach admin_users_sessions_registered_summary $sql {
    if { $n_days > 60 && (![info exists go_beyond_60_days_p] || !$go_beyond_60_days_p) } {
	append table_rows "<tr><td colspan=3 align=center>&nbsp;</td></tr>\n"
	append table_rows "<tr><td colspan=3 align=center><a href=\"sessions-registered-summary?go_beyond_60_days_p=1\">go beyond 60 days...</a></td></tr>\n"
	break
    }
    append table_rows "<tr><th>$n_days<td align=right><a href=\"action-choose?last_login_equals_days=$n_days\">$n_sessions</a><td align=right>$n_repeats</tr>\n"
}


append whole_page "$table_rows
</table>

</blockquote>

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
