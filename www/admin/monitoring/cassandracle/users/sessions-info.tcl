# $Id: sessions-info.tcl,v 3.0 2000/02/06 03:25:39 ron Exp $
# called from ../users/one-user-specific-objects.tcl

set_form_variables 0

set show_sql_p "t"

# get database handle, start building page

ReturnHeaders

ns_write "

[ad_admin_header "Open sessions"]

<h2>Open sessions</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] "Open sessions"]

<!-- version 1.1, 1999-12-08, Dave Abercrombie, abe@arsdigita.com -->
<hr>
"

# make SQL

set db [ns_db gethandle]
# set up for dynamic re-ordering

set order_by [export_var order_by username]

set session_sql "
-- /users/sessions-info.tcl
-- get session info
select
     v\$session.sid,
     username,
     osuser,
     process,
     program,
     type,
     terminal,
     to_char(logon_time, 'YYYY-MM-DD HH24:MI') as logon_time,
     round((sysdate-logon_time)*24,2) as hours_ago,
     serial# as serial,
     v\$session_wait.seconds_in_wait as n_seconds,
     status
from v\$session, v\$session_wait
where v\$session.sid = v\$session_wait.sid
order by $order_by
"

# start building table -----------------------------------


# specify output columns       1         2         3              4         5                6         7           8           9           10 
set description_columns [list "Session" "Serial#"  "Oracle user" "Program" "Seconds in wait"  "Active/Inactive" "UNIX user" "UNIX pid" "Type" "tty" "Logged in" "Hours ago" ]
set column_html ""
foreach column_heading $description_columns {
    append column_html "<th>$column_heading</th>"
}

# begin main table
ns_write "
<table border=1>
<tr>$column_html</tr>
"

# run query (already have db handle) and output rows
set selection [ns_db select $db $session_sql]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    # start row
    set row_html "<tr>\n"

    # 1) session
    append row_html "   <td><a href=\"one-session-info.tcl?sid=$sid\">$sid</a></td>\n"

    # 2) Serial number
    append row_html "   <td>$serial</td>"

    # 3) Oracle user
    if { [string compare $username ""]==0 } {
        set username "&nbsp;"
    }
   
    append row_html "   <td>$username</td>\n"

    # 4) Program
    append row_html "   <td>$program</t>\n"

    # 5) Session length
    append row_html "    <td>$n_seconds</td>\n"

    # 6) Session length
    append row_html "    <td>$status</td>\n"

    # 7) Unix user
    append row_html "   <td>$osuser</td>\n"

    # 8) Unix PID
    append row_html "   <td>$process</td>\n"

    # 9) session type
    append row_html "   <td>$type</td>\n"

    # 10) tty
    if { [string compare $terminal ""]==0 } {
        set terminal "&nbsp;"
    }
    append row_html "   <td>$terminal</td>\n"

    # 10) logged in
    append row_html "   <td>$logon_time</td>\n"

    # 11) hours ago
    append row_html "   <td>$hours_ago</td>\n"

    # close up row
    append row_html "</tr>\n"

    # write row
    ns_write "$row_html"
}

# close up table
ns_write "</table>\n
<p>
See <a href=http://photo.net/wtr/oracle-tips.html#sessions target=other>\"Be Wary of SQLPlus\"</a> in <a href=http://photo.net/wtr/oracle-tips.html target=other>Oracle Tips</a> for how this page be useful in killing hung database sessions.
(Any queries that are ACTIVE and have a high \"Seconds in wait\"
are good canidates to consider killing.)

[ad_admin_footer]
"