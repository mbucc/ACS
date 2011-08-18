# $Id: admin-q-and-a-new-messages.tcl,v 3.0 2000/02/06 03:33:02 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic required

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
<title>$topic Recent Postings</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Recent Postings</h2>

in the <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">$topic Q&A forum</a> (sorted by time rather than by thread)

<p>

(covers last $q_and_a_new_days days)

<hr>


<ul>
"

set sql "select msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name, originating_ip, interest_level, posting_time, substr(sort_key,1,6) as root_msg_id
from bboard, users
where bboard.user_id = users.user_id
and topic_id = $topic_id
and posting_time > sysdate - $q_and_a_new_days
order by sort_key desc"

set selection [ns_db select $db $sql]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $originating_ip == "" } {
	set ip_stuff ""
    } else {
	set ip_stuff "<a href=\"admin-view-one-ip.tcl?originating_ip=[ns_urlencode $originating_ip]&[export_url_vars topic topic_id]\">$originating_ip</a>"
    }
    ns_write "<li>$posting_time: <a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$root_msg_id\">$one_line</a> from $name 
(<a href=\"admin-view-one-email.tcl?email=[ns_urlencode $email]&[export_url_vars topic topic_id]\">$email) 
$ip_stuff"

}

ns_write "

</ul>

[bboard_footer]
"

