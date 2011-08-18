# $Id: next.tcl,v 3.0.4.1 2000/04/28 15:09:42 carsten Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# msg_id is the key, topic_id

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


set selection [ns_db select $db "select msg_id, sort_key
from bboard 
where sort_key > (select sort_key from bboard where msg_id = '$msg_id')
and topic_id = $topic_id
order by sort_key"]

# get one row

ns_db getrow $db $selection

set next_msg_id [ns_set value $selection 0]

# we don't want the rest of the rows

ns_db flush $db

if { $next_msg_id != "" } {

    ad_returnredirect "fetch-msg.tcl?msg_id=$next_msg_id"

} else {

    # no msg to return

    ns_return 200 text/html "<html>
<head>
<title>End of BBoard</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h3>No Next Message</h3>

You've read the last message in the <a target=_top href=\"main-frame.tcl?[export_url_vars topic topic_id]\">$topic</a> BBoard.

</body>
</html>
"

}
