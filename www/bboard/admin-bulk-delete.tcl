ad_page_contract {
    @cvs-id admin-bulk-delete.tcl,v 3.0.12.5 2000/09/22 01:36:43 kevin Exp
} {
    msg_id
    deletion_ids
}


db_1row topic_id_get "select topic_id from bboard_topics
where topic_id = (select topic_id from bboard where msg_id = :msg_id)"
 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}

# OK, user is authorized to edit the root message
# let's check the messages to be deleted

set deletion_ids [util_GetCheckboxValues [ns_conn form] deletion_ids]

if { $deletion_ids == 0 } {
    ad_return_error "No messages selected" "Either there is a bug in my code or you didn't check any boxes for
messages to be deleted."
    return
}

set sort_keys [db_list sort_keys_get "select sort_key 
from bboard 
where msg_id in ('[join $deletion_ids "','"]')"]

foreach sort_key $sort_keys {
    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    if { $thread_start_msg_id != $msg_id } {
	ad_return_return "bug in my software" "and/or someone has been tampering with the deletion_ids

<p>

The offending sort_key was \"$sort_key\" whose thread_start_id I thought was
\"$thread_start_msg_id\" and this did not match \"$msg_id\".

<p>

<table>
<tr>
<td>sort keys<td>deletion ids
</tr>
<tr>
<td>
$sort_keys
<td>

$deletion_ids

</tr>
</table>

<hr>

One of the messages to be deleted doesn't seem to be part of the
thread that you were just editing.  This is probably a bug in my code.
But I'm still not going to do the deletion because it is too much of a
security risk.
"
    return
   }
}

# we're authorized for all the submessages too

db_transaction {
    if {[bboard_file_uploading_enabled_p]} {
	set list_of_files_to_delete [db_list unused "select filename_stub from bboard_uploaded_files where msg_id IN ('[join $deletion_ids "','"]')"]
	
	db_dml unused "delete from bboard_uploaded_files where msg_id in ('[join $deletion_ids "','"]')"
	
	# ADD THE ACTUAL DELETION OF FILES
	if { [llength $list_of_files_to_delete] > 0 } {
	    ns_atclose "bboard_delete_uploaded_files $list_of_files_to_delete"    
	}
    }

    db_dml unused "delete from bboard_thread_email_alerts where thread_id in ('[join $deletion_ids "', '"]')"
    
    db_dml unused "delete from bboard where msg_id in ('[join $deletion_ids "','"]')"
}



doc_return  200 text/html "<html>
<head>
<title>Success</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Success</h2>

<hr>

[llength $deletion_ids] message(s) have been removed from the database.

[bboard_footer]"
