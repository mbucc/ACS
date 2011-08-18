# $Id: admin-bulk-delete-by-email-or-ip.tcl,v 3.0.4.1 2000/04/28 15:09:41 carsten Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, deletion_ids, msg_ids, email or originating_ip

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}




bboard_get_topic_info

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {

   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_hardwired_url_stub]admin-home.tcl?[export_url_vars topic topic_id]"]
    return
}


if {[bboard_admin_authorization] == -1} {
	return
}


# cookie checks out; user is authorized


if { [info exists email] } {
    set class "same email address"
} elseif { [info exists originating_ip] } {
    set class "same ip address"
} else {
    ns_return 200 text/html "neither email nor IP address specified; something wrong with your browser or my code"
    return
}

set deletion_ids [util_GetCheckboxValues [ns_conn form] deletion_ids]

if { $deletion_ids == 0 } {
	ns_return 200 text/html "<html>
<head>
<title>No messages selected</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>No messages selected</h2>

<hr>

Either there is a bug in my code or you didn't check any boxes for
messages to be deleted.

<hr>
<address><a href=\"mailto:[bboard_system_owner]\">[bboard_system_owner]</a></address>
</body>
</html>"
      return
    
}

ReturnHeaders

ns_write "<html>
<head>
<title>Deleting threads in $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Deleting Threads</h2>

with the $class in the <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">$topic question and answer forum</a> 

<hr>


"

ns_write "<ul>\n"

foreach msg_id $deletion_ids {
    set selection [ns_db 1row $db "select sort_key, one_line, topic as msg_topic, email as msg_email, originating_ip as msg_originating_ip
from bboard, users
where users.user_id = bboard.user_id 
and msg_id = '$msg_id'"]
    set_variables_after_query
    if { $topic != $msg_topic } {
	ns_write "<li>skipping $one_line because its topic ($msg_topic) does not match that of the bboard you're editing; this is probably a bug in my software\n"
    }
    if { [info exists email] && ( $msg_email != $email ) } {
	ns_write "<li>skipping $one_line because its email address ($msg_email) does not match that of the other messages you're supposedly deleting; this is probably a bug in my software\n"
    }
    if { [info exists originating_ip] && ( $msg_originating_ip != $originating_ip ) } {
	ns_write "<li>skipping $one_line because its originating IP address ($msg_originating_ip) does not match that of the other messages you're supposedly deleting; this is probably a bug in my software\n"
    }
    ns_write "<li>working on \"$one_line\" and its dependents... \n"
    set dependent_key_form [dependent_sort_key_form $sort_key]

    with_transaction $db {

    if {[bboard_file_uploading_enabled_p]} {
	set list_of_files_to_delete [database_to_tcl_list $db "select filename_stub from bboard_uploaded_files where msg_id IN (select msg_id from bboard where msg_id='$msg_id' or sort_key like '$dependent_key_form')"]

	ns_db dml $db "delete from bboard_uploaded_files where msg_id IN (select msg_id from bboard where msg_id='$msg_id' or sort_key like '$dependent_key_form')"
	# ADD THE ACTUAL DELETION OF FILES
	if { [llength $list_of_files_to_delete] > 0 } {
	    ns_atclose "bboard_delete_uploaded_files $list_of_files_to_delete"
	}
    }
	
	ns_db dml $db "delete from bboard_thread_email_alerts where thread_id = '$msg_id'"

	ns_db dml $db "delete from bboard 
where msg_id = '$msg_id' 
or sort_key like '$dependent_key_form'"

	ns_write "success! (killed message plus [expr [ns_ora resultrows $db] - 1] dependents)\n"
    } {
	ns_write "failed.  Database choked up \"$errmsg\"\n"
    }
}

ns_write "

</ul>

[bboard_footer]
"
