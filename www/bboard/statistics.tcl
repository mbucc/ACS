# $Id: statistics.tcl,v 3.0 2000/02/06 03:34:43 ron Exp $
set_the_usual_form_variables 0

# topic and topic_id (optional), show_total_bytes_p (optional (takes a long time))

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if { ![info exists topic_id] || [empty_string_p $topic_id] } {
    set page_title "[bboard_system_name] Statistics"
    set page_headline $page_title
    set where_clause ""
    set and_clause ""
    set context_bar "[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] "Statistics"]"
    set calendar_html [calendar_small_month -day_number_template "<a href=\"threads-one-day-across-system.tcl?julian_date=\$julian_date\"><font size=-1>\$day_number</font></a>"] 
} else {
    set page_title "$topic Statistics"
    set page_headline "Statistics for the $topic Forum"
    if { [bboard_get_topic_info] == -1 } {
	# bboard_get_topic_info will have returned an error page
	return
    }
    set where_clause "\nwhere topic_id = $topic_id"
    set and_clause "\nand topic_id = $topic_id"
    set context_bar "[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Statistics"]"
    set calendar_html [calendar_small_month -day_number_template "<a href=\"threads-one-day.tcl?[export_url_vars topic_id topic]&julian_date=\$julian_date\"><font size=-1>\$day_number</font></a>"] 
}

if { ![info exists show_total_bytes_p] || !$show_total_bytes_p } {
    set kbytes_item ""
} else {
    set kbytes_item ", to_char(round(sum(dbms_lob.getlength(message))/1000,2), '999G999G999G999') as n_kbytes"
}

ReturnHeaders

ns_write "[bboard_header $page_title]

<h2>$page_headline</h2>

$context_bar

<hr>

<table width=100% cellspacing=20>
<tr>
<td valign=top>

<ul>
"

set selection [ns_db 1row $db "select max(posting_time) as max_date, min(posting_time) as min_date, to_char(count(*), '999G999G999G999') as n_msgs $kbytes_item
from bboard $where_clause"]

set_variables_after_query

ns_write "
<li>First message:  $min_date
<li>Most recent posting:  $max_date
<li>Number of archived messages:  $n_msgs
(<a href=\"threads-by-day.tcl?[export_url_vars topic topic_id]\">view by day</a>)
"

if [info exists n_kbytes] {
    # we queried for it
    ns_write "\n<li>Number of kbytes:  $n_kbytes\n"
} else {
    ns_write "\n<li>If you don't mind waiting for a few seconds, you can 
<a href=\"statistics.tcl?show_total_bytes_p=1&[export_url_vars topic topic_id]\">ask 
for a report including total number of bytes in the messages</a>\n"
}

ns_write "

</ul>

</td>
<td valign=top>

$calendar_html 

</td>
</tr>

</table>


Note that these data do not include messages that were deleted (or
marked for expiration) by the forum moderator.

<h3>Active Contributors</h3>

<ul>

"

set selection [ns_db select $db "select bboard.user_id, first_names, last_name, count(*) as n_contributions 
from bboard, users
where bboard.user_id = users.user_id $and_clause
group by bboard.user_id, first_names, last_name
having count(*) > trunc($n_msgs/200)
order by n_contributions desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set complete_anchor "<a href=\"/shared/community-member.tcl?user_id=$user_id\">$first_names $last_name</a>"
    ns_write "<li>$complete_anchor ($n_contributions)\n"
}

ns_write "
</ul>

[bboard_footer]
"
