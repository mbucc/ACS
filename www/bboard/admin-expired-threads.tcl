# $Id: admin-expired-threads.tcl,v 3.0 2000/02/06 03:32:55 ron Exp $
set_the_usual_form_variables

# topic, topic_id

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}



ReturnHeaders

ns_write "<html>
<head>
<title>Expired threads in $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Expired Threads</h2>

in the <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>


"

set sql "select to_char(posting_time,'YYYY-MM-DD') as posting_date, msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name, interest_level
from bboard, users 
where bboard.user_id = users.user_id
and topic_id = $topic_id
and (posting_time + expiration_days) < sysdate
and refers_to is null
order by sort_key $q_and_a_sort_order"


set selection [ns_db select $db $sql]

ns_write "<ul>\n"

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    ns_write "<li>$posting_date:  <a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id\">$one_line</a>
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	ns_write " -- interest level $interest_level"
    }
}

if { $counter == 0 } {
    ns_write "there are no expired threads right now"
}

ns_write "

</ul>

The only thing that you can do with these is <a
href=\"admin-expired-threads-delete.tcl?[export_url_vars topic topic_id]\">nuke them all</a>.  If you
want to preserve a thread, click on it and reset its expiration days
to be blank and/or enough to take it off this list.

[bboard_footer]
"
