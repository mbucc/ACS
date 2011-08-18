# $Id: admin-q-and-a-unanswered.tcl,v 3.0 2000/02/06 03:33:10 ron Exp $
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
<title>$topic Unanswered Questions</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Unanswered Questions</h2>

in the <a href=\"admin-q-and-a.tcl?[export_url_vars topic topic_id]\">$topic Q&A forum</a>

<hr>

<ul>
"

# we want only top level questions that have no answers

set sql "select msg_id, one_line, sort_key,  email, first_names || ' ' || last_name as name,  interest_level
from  bboard bbd1, users
where topic_id = $topic_id
and bbd1.user_id = users.user_id
and 0 = (select count(*) from bboard bbd2 where bbd2.refers_to = bbd1.msg_id)
and refers_to is null
order by sort_key $q_and_a_sort_order"

set selection [ns_db select $db $sql]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id\">$one_line</a>
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	ns_write " -- interest level $interest_level"
    }
}

ns_write "

</ul>

[bboard_footer]
"

