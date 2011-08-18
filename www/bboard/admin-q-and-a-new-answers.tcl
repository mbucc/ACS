# $Id: admin-q-and-a-new-answers.tcl,v 3.0 2000/02/06 03:33:01 ron Exp $
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


# we found subject_line_suffix at least 
set_variables_after_query

ReturnHeaders

ns_write "<html>
<head>
<title>$topic Recent Answers</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Recent Answers</h2>

in the <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">$topic Q&A forum</a>

<hr>

<ul>
"

set sql "select bnah.root_msg_id,count(*) as n_new,max(bnah.posting_time) as max_posting_time, to_char(max(bnah.posting_time),'YYYY-MM-DD') as max_posting_date, bboard.one_line as subject_line
from bboard_new_answers_helper bnah, bboard
where bnah.posting_time > sysdate - 7
and bnah.root_msg_id = bboard.msg_id
and bnah.topic_id = $topic_id
group by root_msg_id, bboard.one_line
order by max_posting_time desc"

set selection [ns_db select $db $sql]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $n_new == 1 } {
	set answer_phrase "answer, "
    } else {
	set answer_phrase "answers, last "
    }
    ns_write "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$root_msg_id\">$subject_line</a> ($n_new new $answer_phrase on [util_IllustraDatetoPrettyDate $max_posting_date])"

}

ns_write "

</ul>

[bboard_footer]
"

