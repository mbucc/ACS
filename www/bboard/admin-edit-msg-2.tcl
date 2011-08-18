# $Id: admin-edit-msg-2.tcl,v 3.0 2000/02/06 03:32:50 ron Exp $
set_the_usual_form_variables

# msg_id, one_line, message, html_p

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


set selection [ns_db 1row $db "select bboard_topics.topic, bboard.topic_id, users.first_names || ' ' || users.last_name as name, users.email 
from bboard, users, bboard_topics
where bboard.user_id = users.user_id
and bboard_topics.topic_id = bboard.topic_id
and msg_id = '$msg_id'"]
set_variables_after_query

if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}

ns_db dml $db "begin transaction"

# is this usgeospatial?
if { [info exists usgeospatial_p] } {
    set other_columns "epa_region = '$QQepa_region',
usps_abbrev = '$QQusps_abbrev',
fips_county_code = '$QQfips_county_code',
"
} else {
    set other_columns ""
}

if { [string length $QQmessage] < 4000 } {
    ns_db dml $db "update bboard 
set one_line = '$QQone_line',
html_p='$html_p',
$other_columns
message = '$QQmessage'
where msg_id = '$msg_id'"
} else {
    ns_ora clob_dml $db "update bboard 
set one_line = '$QQone_line',
html_p='$html_p',
$other_columns
message = empty_clob()
where msg_id = '$msg_id'
returning message into :one" $message
}

ns_db dml $db "end transaction"

ReturnHeaders
ns_write "<html>
<head>
<title>\"$one_line\" updated</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h3>Message $one_line</h3>

Updated in the database - 
(<a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">main admin page</a>)



<hr>

<ul>
<li>subject line:  $one_line
<li>from:  $name ($email)
"

if { [info exists usgeospatial_p] } {
    ns_write "<li>EPA Region: $epa_region
<li>USPS: $usps_abbrev
<li>FIPS: $fips_county_code
"
}

ns_write "<li>message: [util_maybe_convert_to_html $message $html_p]
</ul>




[bboard_footer]
</body>
</html>"
