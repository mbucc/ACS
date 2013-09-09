# /www/bboard/do-delete.tcl
ad_page_contract {
    deletes a msg (or set of messages) from a bulletin board
    and any associated attachments; used only by the administrator

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    @param submit_button send email or not?
    @param explanation why we are deleting
    @param explanation_from who is deleting
    @param explanation_to who is being deleted
    @param deletion_list list of msg ids to delete
    @param user_charge how much to charge the culprit

    @author philg@mit.edu
    @creation-date 1995
    @cvs-id do-delete.tcl,v 3.2.2.6 2000/09/22 01:36:49 kevin Exp
} {
    topic
    topic_id:integer,notnull
    submit_button
    explanation:html
    explanation_from
    explanation_to
    deletion_list
    user_charge:optional
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

for { set i 0 } { $i < [llength deletion_list] } {incr i} {
    set delete_list_$i [lindex $deletion_list $i]
    lappend delete_list ":delete_list_$i"
}

db_transaction {

    if {[bboard_file_uploading_enabled_p]} {
	set list_of_files_to_delete [db_list delete_files "
	select filename_stub from bboard_uploaded_files 
	where msg_id in ( [join $delete_list ","] )"]

	db_dml file_delete "
	delete from bboard_uploaded_files 
	where msg_id in ( [join $delete_list ","] )"
	
	# ADD THE ACTUAL DELETION OF FILES
	if { [llength $list_of_files_to_delete] > 0 } {
	    ns_atclose "bboard_delete_uploaded_files $list_of_files_to_delete"
	}
    }

    db_dml alerts_delete "
    delete from bboard_thread_email_alerts 
    where thread_id in ( [join $delete_list ","] )"

    set delete_sql "
    delete from bboard where msg_id in ( [join $delete_list ","] )"

    if [catch { db_dml msg_delete $delete_sql} errmsg] {

	db_abort_transaction
	# something went a bit wrong during the delete
	ad_return_error "error deleting messages"  "Error deleting messages.  This should never have happened.  Here was the message:
	<pre>

	$errmsg

	</pre>
	" 
	return

    }
}
	


append page_content "
[ad_admin_header "Deletion Successful"]

<h2>Deletion successful.</h2>
<hr>

The thread you picked has been removed from the discussion.  You can 
<a href=\"admin-home?[export_url_vars topic topic_id]\">return to the 
administration home page for \"$topic\"</a>"

if { [string first "Email" $submit_button] != -1 } { 
    # we have to send some email
    append page_content "<p>... sending email to $explanation_to (from $explanation_from) ..."
    if [catch { ns_sendmail $explanation_to $explanation_from "your thread has been deleted" $explanation } errmsg] {
	append page_content " failed sending mail:  <pre>\n$errmsg\n</pre>"
    } else {
	# mail was sent
	append page_content "... completed sending mail"
    }
}

if { [info exists user_charge] && ![empty_string_p $user_charge] } {
    append page_content "<p> ... adding a user charge:
    <blockquote>
    [mv_describe_user_charge $user_charge]
    </blockquote>
    ... "
    mv_charge_user $user_charge
    append page_content "Done."
}

append page_content "

[ad_footer]
"


doc_return  200 text/html $page_content

