# $Id: subject.tcl,v 3.0 2000/02/06 03:34:45 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic_id, topic required
# start_msg_id is optional (used to show start of thread)
# feature_msg_id is optional (used to highlight a msg)

set db [ns_db gethandle]
 
if  {[bboard_get_topic_info] == -1} {
    return}


if { [info exists start_msg_id] && $start_msg_id != "" } {
    set sql "select msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name 
from bboard , users
where users.user_id = bboard.user_id
and topic_id = $topic_id
and msg_id >= '$start_msg_id'
order by sort_key"
} else {
    set sql "select msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name
from bboard, users
where users.user_id = bboard.user_id 
and topic_id = $topic_id
order by sort_key"
}

ReturnHeaders

ns_write "<html>
<head>
<title>Subject Window for $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<pre>"

set selection [ns_db select $db $sql]

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter

    set n_spaces [expr 3 * [bboard_compute_msg_level $sort_key]]
    if { $n_spaces == 0 } {
	set pad ""
    } else {
	set pad [format "%*s" $n_spaces " "]
    }

    if { [info exists feature_msg_id] && $feature_msg_id == $msg_id } {
	set display_string "<b>$one_line</b>"
    } else {
	set display_string "$one_line"
    }

    if { $subject_line_suffix == "name" } {
	append display_string "  ($name)"
    } elseif { $subject_line_suffix == "email" } {
	append display_string "  ($email)"
    }
    ns_write "$pad<a target=main href=\"fetch-msg.tcl?msg_id=$msg_id\">$display_string</a>\n"

}

if { $counter == 0 } {
    ns_write "there have been no messages posted to this forum"
}

ns_write "</pre>
</body>
</html>
"
