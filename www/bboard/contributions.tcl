# $Id: contributions.tcl,v 3.0 2000/02/06 03:33:41 ron Exp $
set_form_variables

# user_id

# displays the contibutions of this member to the bboard

set db [bboard_db_gethandle]

set selection [ns_db 0or1row $db "select first_names, last_name from users where user_id = $user_id"]
if { $selection == "" } {
    ns_return 200 text/html "can't figure this user in the database"
    return
}

set_variables_after_query

ReturnHeaders

ns_write "[bboard_header "$first_names $last_name"]

<h2>$first_names $last_name</h2> 

as a contributor to <A HREF=\"/bboard/\">the discussion forums</a> in 
<a href=/>[ad_system_name]</a>
<hr>

<ul>
"

set selection [ns_db select $db "select one_line, msg_id,  posting_time, sort_key, bboard_topics.topic, presentation_type 
from bboard, bboard_topics 
where bboard.user_id = $user_id
and bboard.topic_id = bboard_topics.topic_id
order by posting_time asc"]

set n_rows_found 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr n_rows_found
    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    ns_write "<li>[util_IllustraDatetoPrettyDate $posting_time]: <a href=\"/bboard/[bboard_msg_url $presentation_type $thread_start_msg_id $topic]\">$one_line</a>\n"
}
    
if { $n_rows_found == 0 } {
    ns_write "no contributions found"
}
    
ns_write "
</ul>
   
[bboard_footer]
"
