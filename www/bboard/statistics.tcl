# /www/bboard/statistics.tcl
ad_page_contract {
    Displays statistics for the bboard system

    @param topic bboard topic to restrict to
    @param topic_id the ID of the topic
    @param show_total_bytes_p whether to display the total size of all 
           messages

    @cvs-id statistics.tcl,v 3.2.2.4 2000/08/05 20:48:07 ron Exp
} {
    topic:optional
    topic_id:optional,integer
    show_total_bytes_p:optional
}

# -----------------------------------------------------------------------------

if { ![exists_and_not_null topic_id] } {
    set page_title "[bboard_system_name] Statistics"
    set page_headline $page_title
    set where_clause ""
    set and_clause ""
    set context_bar "[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] "Statistics"]"
    set calendar_html [calendar_small_month -day_number_template "<a href=\"threads-one-day-across-system?julian_date=\$julian_date\"><font size=-1>\$day_number</font></a>"] 

} else {

    set page_title "$topic Statistics"
    set page_headline "Statistics for the $topic Forum"
    if { [bboard_get_topic_info] == -1 } {
	# bboard_get_topic_info will have returned an error page
	return
    }
    set where_clause " where topic_id = :topic_id"
    set and_clause " and topic_id = :topic_id"
    set context_bar "[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Statistics"]"
    set calendar_html [calendar_small_month -day_number_template "<a href=\"threads-one-day?[export_url_vars topic_id topic]&julian_date=\$julian_date\"><font size=-1>\$day_number</font></a>"] 
}

if { ![info exists show_total_bytes_p] || !$show_total_bytes_p } {
    set kbytes_item ""
} else {
    set kbytes_item ", to_char(round(sum(dbms_lob.getlength(message))/1000,2), '999G999G999G999') as n_kbytes"
}

append page_content "
[bboard_header $page_title]

<h2>$page_headline</h2>

$context_bar

<hr>

<table width=100% cellspacing=20>
<tr>
<td valign=top>

<ul>
"

db_1row statistics "
select max(posting_time) as max_date, 
       min(posting_time) as min_date, 
       count(*) as n_msgs,
       to_char(count(*), '999G999G999G999') as pretty_n_msgs $kbytes_item
from bboard $where_clause "

append page_content "
<li>First message:  $min_date
<li>Most recent posting:  $max_date
<li>Number of archived messages:  $pretty_n_msgs"

if [exists_and_not_null topic_id] {
    append page_content "
    (<a href=threads-by-day?[export_url_vars topic topic_id]>view by day</a>)"
}

if [info exists n_kbytes] {
    # we queried for it
    append page_content "\n<li>Number of kbytes:  $n_kbytes\n"
} else {
    append page_content "\n<li>If you don't mind waiting for a few seconds, you can 
<a href=\"statistics?show_total_bytes_p=1&[export_url_vars topic topic_id]\">ask 
for a report including total number of bytes in the messages</a>\n"
}

append page_content "

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

db_foreach active_users "
select bboard.user_id, 
       first_names, 
       last_name, 
       count(*) as n_contributions 
from   bboard, users
where  bboard.user_id = users.user_id $and_clause
group  by bboard.user_id, first_names, last_name
having count(*) > trunc(:n_msgs / 200)
order by n_contributions desc" {

    set complete_anchor "<a href=\"/shared/community-member?user_id=$user_id\">$first_names $last_name</a>"
    append page_content "<li>$complete_anchor ($n_contributions)\n"
}

append page_content "
</ul>

[bboard_footer]
"


doc_return  200 text/html $page_content
