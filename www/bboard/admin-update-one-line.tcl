# $Id: admin-update-one-line.tcl,v 3.0.4.1 2000/04/28 15:09:41 carsten Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# msg_id is the key, one_line

set db [bboard_db_gethandle]

set topic_id [database_to_tcl_string $db "select unique topic_id from bboard where msg_id = '$msg_id'"]

bboard_get_topic_info


 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}


# we're authorized 

ns_db dml $db "update bboard set one_line = '$QQone_line' where msg_id = '$msg_id'"

ad_returnredirect "admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id"
