# $Id: admin-delete-and-view-threads.tcl,v 3.0 2000/02/06 03:32:45 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, topic_id

 


set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


# cookie checks out; user is authorized

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}



proc compute_msg_level { sort_key } {

    set period_pos [string first "." $sort_key]

    if { $period_pos == -1 } {

	# no period, primary level

	return 0

    } else {

	set n_more_levels [expr ([string length $sort_key] - ($period_pos + 1))/2]

	return $n_more_levels

    }


}

ReturnHeaders

ns_write "<html>
<head>
<title>Delete and View Threads for $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Delete and View Threads for \"$topic\"</h2>

a discussion group in <a href=\"index.tcl\">[bboard_system_name]</a>

<p>

Personally, I don't find this interface as useful as the 

<a href=\"admin-q-and-a.tcl?[export_url_vars topic topic_id]\">admin Q&A</a>

but to each his own...

<hr>

<h3>Those Threads</h3>

<pre>"

set selection [ns_db select $db "select msg_id, one_line, sort_key from bboard
where topic_id = $topic_id
order by sort_key desc"]

while {[ns_db getrow $db $selection]} {

    set_variables_after_query

    set n_spaces [expr 3 * [compute_msg_level $sort_key]]

    if { $n_spaces == 0 } {

	set pad ""

    } else {

	set pad [format "%*s" $n_spaces " "]

    }

    ns_write "<a target=admin_bboard_window href=\"delete-msg.tcl?msg_id=$msg_id\">DELETE</a> $pad<a target=admin_bboard_window href=\"admin-edit-msg.tcl?msg_id=$msg_id\">$one_line</a>\n"

}

ns_write "</pre>
</body>
</html>
"
