# /www/admin/monitoring/top/index.tcl

ad_page_contract {
    Displays reports from saved top statistics.

    @param n_days     the # of days over which to average
    @param start_time taken between the given start
    @param end_time   and end times on each day
    @param orderby    the field by which to order the procedure-specific data
    @param orderbysystem field by which to order the system_avg data
    @param showtop       show the top of the moment? (boolean)
    @param min_cpu_pct   procs with CPU below this aren't displayed

    @authors       sklein@arsdigita.com, mbryzek@arsdigita.com
    @creation-date May 2000
    @cvs-id        index.tcl,v 1.18.2.5 2000/09/22 01:35:40 kevin Exp
} {
    {n_days 1}
    {start_time "00"}
    {end_time 24}
    {orderby  "cpu_pct"}
    {orderbysystem "day"}
    {min_cpu_pct 20}
    {showtop "f"}
}


### Define table definitions for ad_table
##
set top_proc_avg_table_def {
    {timestamp "Hour" {} {}}
    {threads "Thr" {} {}}
    {command "Command" {} \
	    {<td align=right><a href="details?key=command&value=[ad_urlencode $command]">$command</a></td>}}
    {username "Username" {} \
	    {<td><a href="details?key=username&value=$username">$username</a></td>}}
    {pid "PID" {} \
	    {<td><a href="details?key=pid&value=$pid">$pid</a></td>}}
    {cpu_pct "CPU" {} {}}
    {count "Cnt" {} {}}
}  

set top_system_avg_table_def {
    {day  "date" {} \
	    {<td><a href="details?key=day&value=[ad_urlencode $day]">$day</a></td>}}
    {load_average "load" {} {}}
    {memory_free_average "free mem" {} \
	    {<td>[ad_monitor_format_kb $memory_free_average]</td>}}
    {memory_swap_free_average "free swap" {} \
	    {<td>[ad_monitor_format_kb $memory_swap_free_average]</td>}}
    {memory_swap_in_use_average "used swap" {} \
	    {<td>[ad_monitor_format_kb $memory_swap_in_use_average]</td>}}
    {count "count" {} {}}
}  

#### Set up sql for the rest of the page

# here are all the bind variables needed by both queries
set bind_vars [ad_tcl_vars_to_ns_set start_time end_time min_cpu_pct n_days]


##
## 1. Create the sql to filter by date and time

set time_clause "where timehour >= :start_time
                   and timehour < :end_time"

if { [string compare $n_days "all"] != 0 } {
    # Need to multiply n_days by ($end_time-to_char(sysdate,'HH24'))/24 to 
    # get accurate current snapshots.  That is, displaying back in time
    # needs to be relative to the selected end_time, not to sysdate.

    set current_hour [db_string mon_current_hour \
	    "select to_char(sysdate,'HH24') from dual"]

    if { $end_time > $current_hour } {
	# we correct for the last day in the query if the end time
	# is later than the current time.
	set hour_correction " + (24 - (:end_time - :current_hour)) / 24 "
    } else {
	set hour_correction ""
    }

    append time_clause " and (timestamp + :n_days $hour_correction) > sysdate"
}

### 2. Create the sql to fill top_proc_avg_table, grouping proc info
###    by pid and averaging over each hour(day) that pid was running
###    (default to hour).  We need to be careful about avging over
###    the whole time period b/c the same pid is eventually used by 
###    distinct processes.
set hour_sql "to_char(timestamp, 'MM/DD HH24') || ':00'"
set day_sql  "to_char(timestamp, 'Mon DD')"
## 

set avg_proc_query "
  select pid, command, username,
         count(*) as count,
         $hour_sql as timestamp,
         round(avg(threads)) as threads,
         round(avg(to_number(rtrim(cpu_pct, '%'))), 2) as cpu_pct
    from ( select * from ad_monitoring_top $time_clause ) t, 
         ( select * from ad_monitoring_top_proc 
            where to_number(rtrim(cpu_pct, '%')) > :min_cpu_pct ) p
   where p.top_id = t.top_id
   group by pid, command, username, $hour_sql
   [ad_order_by_from_sort_spec $orderby $top_proc_avg_table_def] 
"
# [ad_table_orderby_sql $top_proc_avg_table_def $orderby "DESC"]
set load_and_memory_averages_sql "round(nvl(avg(load_avg_1), 0),  2) as load_average, 
         round(nvl(avg(memory_free),0), -2) as memory_free_average, 
         round(nvl(avg(memory_swap_free),  0), -2) as memory_swap_free_average,
         round(nvl(avg(memory_swap_in_use),0), -2) as memory_swap_in_use_average
"

## the query to get system averages for each requested day.  This is not
## the only query for display in an ad_table; note that "system" is tacked 
## onto the end of the orderby variable [and elsewhere as regards this query].
set avg_system_query "
  select $load_and_memory_averages_sql,
         count(*) as count,
         $day_sql as day
    from ad_monitoring_top
         $time_clause
   group by $day_sql
   [ad_order_by_from_sort_spec $orderbysystem $top_system_avg_table_def] 
"
#  [ad_table_orderby_sql $top_system_avg_table_def $orderbysystem "DESC"]

### Begin returning the page.
append page_content "
 [ad_header "Statistics From Top"]
   <h2>Statistics from Top</h2>
 [ad_admin_context_bar [list ../ "Monitoring"] "Top"]
   <hr>
<table width=100%>
 <tr><td align=right>
   <a href=index?showtop=t&[export_ns_set_vars url [list showtop]]>show top now</a></td>
</tr>
</table>
"

# add a doc_body_flush here

set n_days_list [list]
foreach n [list 1 2 3 7 14 31 all] {
    if { $n == $n_days } {
	lappend n_days_list "<b>$n</b>"
    } else {
	lappend n_days_list "<a href=index?n_days=$n&[export_ns_set_vars url [list n_days showtop]]>$n</a>"
    }
}

set start_select ""
set end_select ""
for { set i 0 } { $i < 25 } { incr i } {
    if { $i == 0 | $i == 24 } {         set text "Midnight"
     } elseif { $i == 12 } { set text "Noon"
     } elseif { $i > 12 } {  set text "[expr {$i - 12}] pm"
     } else {                set text "$i am"
    }

    append start_select " <option value=\"$i\"[if {$i == $start_time} {
           set foo " selected"}]> $text\n"

    append end_select   " <option value=\"$i\"[if {$i == $end_time} {
           set foo " selected"}]> $text\n"
}

set cpu_select ""
foreach percent {0 1 2 5 10 20 30 40 50 75} {
    append cpu_select " <option value=\"$percent\"[if {$percent == $min_cpu_pct} {
	set foo " selected"}]> $percent%\n"
}

# This form only includes the time-selection drop-down menus,
# so we quietly pass in the other important variables
# Also, the rest of the page is slow, so we ns_write the top
# section, in case the user wants to change the default parameters.
append page_content "
<form method=get action=index>
[export_form_vars n_days orderby orderbysystem]

<table cellspacing=1 width=70%>
<tr>
  <td colspan=3> <blockquote> Select the time of day during which you wish 
     to monitor system information, and the number of days over which you wish 
     to calculate any averages. </blockquote> </td>
</tr>
<tr bgcolor=cccccc>
  <th>Number of days</th>  <th>Start time - End time</th>  <th>Min CPU %</th>
</tr>
<tr>
  <td valign=top align=center>[join $n_days_list " | "]</td>
  <td valign=top align=center>
      <select name=start_time>$start_select</select> - 
         <select name=end_time>$end_select</select>
  <td valign=top align=center>
      <select name=min_cpu_pct>$cpu_select</select>  
      <input type=submit value=Go>
  </td>
</tr>
</table>
</form>
"

set top_location [ad_parameter TopLocation monitoring "/usr/local/bin/top"]

if { [string match $showtop "t"] } {
    if [catch { set top_output [exec $top_location] } errmsg] {
        # couldn't exec top at TopLocation
        if { ![file exists $top_location] } {
	    ad_return_error "top not found" "
	    The top procedure could not be found at $top_location:
	    <blockquote><pre> $errmsg </pre></blockquote>"
	    return
        }
        
        ad_return_error "insufficient top permissions" "
	The top procedure at $top_location cannot be run:
	<blockquote><pre> $errmsg </pre></blockquote>"
        return  
    }
    # top execution went ok
    append page_content "<h4>Current top output on this machine</h4>
    <pre>$top_output</pre>
    [ad_admin_footer]"
    doc_return  200 text/html $page_content
    return
}

set number_rows [db_string mon_top_entries \
	         "select count(*) from ad_monitoring_top $time_clause"]

if { $number_rows == 0 } {
    append page_content  "
       <ul><li><b> No data for the selected time period</b></ul>
       [ad_admin_footer]"
    doc_return  200 text/html $page_content
    return
} else {
    db_1row mon_top_load_and_memory_averages \
        "select $load_and_memory_averages_sql from ad_monitoring_top $time_clause"

    set num_days [db_string num_days_for_query \
	    "select round(max(timestamp) - min(timestamp) + 0.5) 
                  from ad_monitoring_top $time_clause"]

    append page_content "<h4>Overall statistics</h4>  

<ul><li>[util_commify_number $number_rows] 
  top measurement[util_decode $number_rows 1 "" "s"] on $num_days 
  distinct day[util_decode $num_days 1 "" "s"] satisfied your query <br>
  (between [append start_time ":00"] and [append end_time ":00"] Hrs 
  over the past $n_days days).
    <li>Average <b>load</b>: [format "%6.2f" $load_average].
    <li>Average <b>free memory</b>: [ad_monitor_format_kb $memory_free_average]
    <li>Average <b>free swap</b>: [ad_monitor_format_kb $memory_swap_free_average]
    <li>Average <b>used swap</b>: [ad_monitor_format_kb $memory_swap_in_use_average]
</ul>


<h4>Averages over each day during this time range:</h4>
"
}

# we include a "system" suffix in this call to ad_table to use 
# the right orderby variable

append page_content "
[ad_table -Tsuffix system -bind $bind_vars \
	mon_system_averages $avg_system_query $top_system_avg_table_def]
<hr width=70%>

[ad_table -bind $bind_vars \
	mon_proc_averages $avg_proc_query $top_proc_avg_table_def]
<p>
"

### clean up, return page.
append page_content "</table>  [ad_admin_footer]"

doc_return  200 text/html $page_content

##### EOF
