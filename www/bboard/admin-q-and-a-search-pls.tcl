# $Id: admin-q-and-a-search-pls.tcl,v 3.0 2000/02/06 03:33:08 ron Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# query_string, topic

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
<title>Search Results</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Messages matching \"$query_string\"</h2>

in the <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">$topic</a> forum.

<hr>
\[ <a href=\"q-and-a-post-new.tcl?[export_url_vars topic topic_id]\">Ask New Question</a> \]

<ul>
"

regsub -all { +} $query_string "," query_string_for_ctx
regsub -all {,+} $query_string_for_ctx "," query_string_for_ctx

set selection [ns_db select $db "select msg_id, sort_key, one_line,  first_names || ' ' || last_name as name, email
from bboard, users
where bboard.user_id = users.user_id
and contains (indexed_stuff, '\$([DoubleApos $query_string_for_ctx])', 10) > 0
and topic_id=$topic_id
order by score(10) desc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    ns_write "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$thread_start_msg_id\">$one_line</a>
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
}

ns_write "
</ul>

<form method=POST action=admin-q-and-a-search-pls.tcl target=\"_top\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
New Search:  <input type=text name=query_string size=40 value=\"$query_string\">
</form>

[bboard_footer]
"
