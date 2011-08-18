# $Id: post-reply-top.tcl,v 3.0 2000/02/06 03:34:09 ron Exp $
set_form_variables

# refers_to is the key

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


set selection [ns_db 1row $db "select first_names || ' ' || last_name as name, email, bboard.* 
from bboard, users
where bboard.user_id = users.user_id
and msg_id = '$refers_to'"]

set_variables_after_query

# now variables like $message are defined

ns_return 200 text/html "<html>
<head>
<title>$one_line</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h3>$one_line</h3>

from $name (<a href=\"mailto:$email\">$email</a>)

<hr>

$message

</body>
</html>
"
